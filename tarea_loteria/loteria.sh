#!/bin/bash
echo "Hello" "$USER"

# 1) Descarga directorio si no existe

if [ ! -f ./denue_71_25022015_csv.zip ]; then
    echo "Folder de INEGI not found!"
    curl http://www.beta.inegi.org.mx/contenidos/masiva/denue/denue_71_25022015_csv.zip --output denue_71_25022015_csv.zip
    # 2) Descompacta archivo
    unzip denue_71_25022015_csv.zip
fi

sed ':l;s/,,/,"NA",/;tl;' DENUE_INEGI_71_.csv > DENUE_INEGI_71_non_empty.csv
 
#non empty ya estan bien, ahora necesitamos separar con pipes los valores que estan entre commillas

tr “'\"."'” “'\|\"."'” < ./DENUE_INEGI_71_non_empty.csv > DENUE_INEGI_71_pipes.csv

sed -r 's/(\s?\.,.){1}/ |/g' ./DENUE_INEGI_71_pipes.csv > ./DENUE_INEGI_71_pipes1.csv

# Comando para determinar el código SCIAN de centros de venta de loteria y centros de acondicionamiento físico
# Paso 1, determinar la columna en donde aparece la palabra SCIAN 

column_number_scian=$(grep -rnw './DENUE_INEGI_71_pipes1.csv' -e 'SCIAN' | awk -F'|' ' { for (i = 1; i <= NF; ++i) print i, $i; exit } ' | awk '$0 ~ "SCIAN" {print NR}')

# Determinar la columna en donde se puede encontrar la clase de actividad económica

column_number_actividad=$(grep -rnw './DENUE_INEGI_71_pipes1.csv' -e 'Nombre de clase de la actividad' | awk -F'|' ' { for (i = 1; i <= NF; ++i) print i, $i; exit } ' | awk '$0 ~ "Nombre de clase de la actividad" {print NR}')

column_entidad_federativa=$(grep -rnw './DENUE_INEGI_71_pipes1.csv' -e 'Entidad federativa' | awk -F'|' ' { for (i = 1; i <= NF; ++i) print i, $i; exit } ' | awk '$0 ~ "Entidad federativa" {print NR}')

# Una vez que tenemos el número de columna del nombre de la actividad económica, podemos buscar la actividad de 
# "centro de acondicionamiento físico" y después la de "lotería"

# 3) SCIAN de acondicionamiento físico y ventas de billetes de lotería
row_acondicionamiento=$(awk -F'|' '$column_number_actividad ~ "acondicionamiento" {print NR}' ./DENUE_INEGI_71_pipes1.csv | head -n 1)
echo "el SCIAN de centros de acondicionamiento fisico es:"

scian_acondicionamiento=$(sed -n "$row_acondicionamiento"p ./DENUE_INEGI_71_pipes1.csv | cut -d '|' -f"$column_number_scian")
echo "$scian_acondicionamiento"

row_loteria=$(awk -F'|' '$column_number_actividad ~ "lotería" {print NR}' ./DENUE_INEGI_71_pipes1.csv | head -n 1)
echo "el SCIAN de ventas de billetes de loteria es:"

scian_loteria=$(sed -n "$row_loteria"p ./DENUE_INEGI_71_pipes1.csv | cut -d '|' -f"$column_number_scian")
echo "$scian_loteria"

# 4) Genere un archivo csv con el número de expendios de lotería por estado
# Vamos a filtrar las filas en donde SCIAN sea igual al que obtuvimos en el paso anterior en donde mostremos
# también el estado 

# Funciones auxiliares
#sed -n 100p ./DENUE_INEGI_71_non_empty.csv | awk -F'\"."' '{print NF}'

#tr “\,'\"."'” “\|'\"."'” ./DENUE_INEGI_71_non_empty.csv

# existen muchas observaciones erróneas, para saber en que fila están estas observaciones se ejecuta el siguiente comando

awk -F'\"."' '{print NF}' ./DENUE_INEGI_71_non_empty.csv > number_lines.csv

#es para ver los renglones en donde hay campos de cardinalidad menor a 41 que es el normal

grep -rnw '41' ./number_lines.csv | awk -F':' '{print $1}' > valid_lines.csv

# filtrar el archivo de los pipes con los renglones validos

sed -n -f <( sed 's/$/p/' valid_lines.csv ) ./DENUE_INEGI_71_pipes1.csv > ./DENUE_INEGI_71_pipes2.csv

awk -F'|' '$column_number_actividad ~ "lotería" {print}' ./DENUE_INEGI_71_pipes2.csv | cut -d '|' -f"$column_number_actividad","$column_entidad_federativa" > loteria_entidades.csv

cat loteria_entidades.csv | sort | uniq -c > count_loteria_entidad_federativa.csv

cat count_loteria_entidad_federativa.csv

awk -F'|' '$column_number_actividad ~ "acondicionamiento" {print}' ./DENUE_INEGI_71_pipes2.csv | cut -d '|' -f"$column_number_actividad","$column_entidad_federativa" > acondicionamiento_entidades.csv

cat acondicionamiento_entidades.csv | sort | uniq -c > count_acondicionamiento_entidad_federativa.csv

cat count_acondicionamiento_entidad_federativa.csv