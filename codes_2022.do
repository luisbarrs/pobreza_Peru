/*******************************************************************************
  "Rutinas de Medición de pobreza en Stata"
*******************************************************************************/  
  /* Link: Informe técnico de Pobreza Monetaria 2022 - INEI
   https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/pobreza2022/Pobreza2022.pdf  
   
********************************************************************************
*  1  Configuración inicial e instalación de paquetes que se requieran
*******************************************************************************/
  * 1.1 Setear la dirección de trabajo
  cd "D:/ASESORIAS/OTHER/POVERTY"  
  * 1.2 Descargar bases de datos a utilizar
  * Sumarias
  copy "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA/784-Modulo34.zip" "784-Modulo34.zip",replace
  /*capture unzipfile sumaria_784-Modulo34.zip  
  erase sumaria_784-Modulo34.zip*/  //capture y erase permiten obtener las carpetas contenidas en el zip
  * Caracteristicas de la vivienda
  copy "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA/784-Modulo01.zip" "784-Modulo01.zip",replace   
  /*capture unzipfile vivienda_784-Modulo01.zip 
  erase vivienda_784-Modulo01.zip*/
  *1.3 Paquete: sepov
  net describe sg117, from(http://www.stata.com/stb/stb51)  //otra forma help sg117
  net install sg117
  net get sg117
  help sepov
  
********************************************************************************
*  2  Estimación de pobreza monetaria 2022
********************************************************************************
  *2.1 Uso de base de datos sumaria-2022
  use "D:/ASESORIAS/OTHER/POVERTY/784-Modulo34/sumaria-2022.dta",replace
  * Si es muy grande la ubicación se puede utilizar un global
  global ubicacion_s "D:/ASESORIAS/OTHER/POVERTY/784-Modulo34"
  use ${ubicacion_s}/sumaria-2022.dta,replace  
  *2.2 Generación de identificadores para hogares
  gen i = conglome + vivienda + hogar
  sort i
  d gashog2d mieperho
  *2.3 Generación de gasto per-capita mensual
  gen gasto_per = (gashog2d) / (12*mieperho)
  *2.4 Generación de regiones
  gen region = real((substr(ubigeo,1,2)))
  // Unión de hogares Lima-Callao (15 y 7)
  recode region 7 = 15
  label define region 1"AMAZONAS" 2"ANCASH" 3"APURIMAC" 4"AREQUIPA" 5"AYACUCHO"       ///
        6"CAJAMARCA" 8"CUZCO" 9"HUANCAVELICA" 10"HUANUCO" 11"ICA" 12"JUNIN"           ///
        13"LA LIBERTAD" 14"LAMBAYEQUE" 15"LIMA" 16"LORETO" 17"MADRE DE DIOS"          ///
        18"MOQUEGUA"19"PASCO" 20"PIURA" 21"PUNO" 22"SAN MARTIN" 23"TACNA" 24"TUMBES"  ///
        25"UCAYALI"  
  label values region region
  *2.5 Generación del factor de población
  d factor07
  gen factor_pob = factor07 * mieperho
  *2.6 Incorporación del diseño muestral 
  svyset [pweight=factor_pob], strata(estrato) psu(conglome)
  *2.7 Utilización del comando sepov para cálcular los indicadores de pobreza
  d linea linpe
  svy: mean linea     
  svy: mean linpe
  svy: mean linea if region == 04
  svy: mean linpe if region == 04
  ** Pobreza a nivel de pais
  sepov gasto_per [pweight=factor_pob], povline(linea) strata(estrato) psu(conglome)
  **Pobreza a nivel de departamento
  sepov gasto_per [pweight=factor_pob], povline(linea) strata(estrato) psu(conglome) by (region)
  **Pobreza extrema a nivel de pais
  sepov gasto_per [pweight=factor_pob], povline(linpe) strata(estrato) psu(conglome)
  **Pobreza a nivel de departamento 
  sepov gasto_per [pweight=factor_pob], povline(linpe) strata(estrato) psu(conglome) by (region)
  
********************************************************************************
*  3  Estimación de pobreza por NBIs 2022
********************************************************************************
  *3.1 Uso de base de datos vivienda 2022
  use "D:/ASESORIAS/OTHER/POVERTY/784-Modulo01/enaho01-2022-100.dta",replace
  * Si es muy grande la ubicación se puede utilizar un global
  global ubicacion_v "D:/ASESORIAS/OTHER/POVERTY/784-Modulo01"
  use ${ubicacion_v}/enaho01-2022-100.dta,replace
  *3.2 Busqueda de valores perdidos en las NBIs  
  tab1 nbi1 nbi2 nbi3 nbi4 nbi5 
  replace nbi1 = 0 if nbi1 ==.
  replace nbi2 = 0 if nbi2 ==.
  replace nbi3 = 0 if nbi3 ==.
  replace nbi4 = 0 if nbi4 ==.
  replace nbi5 = 0 if nbi5 ==.
  /*foreach nbi in nbi1 nbi2 nbi3 nbi4 nbi5 {
    replace `nbi' = 0 if `nbi' ==.
  }*/    // el bucle repite las mismas acciones de la linea 80-85
  *3.3 Suma de NBIs
  gen nbi = nbi1 + nbi2 + nbi3 + nbi4 + nbi5
  label var nbi "suma NBIs"
  *3.4 Generación niveles de pobreza por nbis
  recode nbi (2/5 = 1 "pobre extremo") (1 = 2 "pobre no extremo") (0=0 "no pobre"),gen(nbis)
  *3.4 Generación de regiones
  gen region = real((substr(ubigeo,1,2)))
  // Unión de hogares Lima-Callao (15 y 7)
  recode region 7 = 15
  label define region 1"AMAZONAS" 2"ANCASH" 3"APURIMAC" 4"AREQUIPA" 5"AYACUCHO"       ///
        6"CAJAMARCA" 8"CUZCO" 9"HUANCAVELICA" 10"HUANUCO" 11"ICA" 12"JUNIN"           ///
        13"LA LIBERTAD" 14"LAMBAYEQUE" 15"LIMA" 16"LORETO" 17"MADRE DE DIOS"          ///
        18"MOQUEGUA"19"PASCO" 20"PIURA" 21"PUNO" 22"SAN MARTIN" 23"TACNA" 24"TUMBES"  ///
        25"UCAYALI"  
  label values region region
  *3.5 Cálculo de la pobreza
  tab nbis [iweight=factor07]
  
  

  
  
  
  
  