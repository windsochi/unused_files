Есть относительно небольшой сайт, а места занимает достаточно много, что существенно сказывается на годовой стоимости резервного копирования. Возникло подозрение, что есть неиспользуемые файлы.

Эта статья как раз и посвящена поиску таких файлов на Drupal (и не только Drupal) сайте.

Как появляются файлы, которые занимают полезное пространство?
Например на сайте некоторое время назад был раздел со статьями. Позже было решено провести реорганизацию структуры и раздел статей удалили. Текст удалили, а фотографии остались. Та же ситуация может произойти и с каталогом товаров.
Одним словом - ни один из сайтов не застрахован от “мусорных” файлов.

В этой статье, с помощью несложных действий, мы почистим сайт.

###### Внимание! Перед любыми манипуляциями с сайтом, пожалуйста, сделайте резервную копию.
#
Определим критерии, по которым файл считается не используемым:

* отсутствует упоминание файла в базе данных
* отсутствует ссылка на файл в исходном коде сайта: тема оформления сайта, стили css, скрипты javascript.

Сделайте дамп базы данных и разместите его в корне сайта.
Там же создайте файл с расширением .sh, например dfindfiles.sh и поместите в него следующий код:
```sh
#!/bin/sh
START=./sites/default/files
CURDIR=`pwd`
IG_STYLES=./styles/*
IG_JS=./js/*
IG_CSS=./css/*

dbdump=`pwd`/dumpwebsite.sql
usedfile=`pwd`/output_used.txt
notusedfile=`pwd`/output_notused.txt
notusedfile_check=`pwd`/output_notused_check.txt

cd ${START}
echo "Step 1. Checking for used and unused files to database..."
echo "$(date) $line"
for file in `find . ! -path "$IG_JS" ! -path "$IG_CSS" ! -path "$IG_STYLES" -type f -print | cut -c 3- | sed 's/ /#}/g'`
do
  file2=`echo $file | sed 's/#}/ /g'`
  file3=`basename $file2`
  result=`grep -c "$file3" $dbdump`
  if [ $result = 0 ]; then
    echo $file2 >> $notusedfile
  else
    echo $file2 >> $usedfile
  fi
done
cd ${CURDIR}

echo "Step 2. Checking files from list not used files..."
echo "$(date) $line"
for p in $(cat $notusedfile); do
  grep -rnw --include=*.{module,inc,php,js,css,html,htm,xml} ${CURDIR} -e $p  > /dev/null || echo $p >> $notusedfile_check;
done

echo "Files checking done."
echo "Check the following text-file for results:"
echo "$notusedfile_check"
```

##### Описание скрипта
#
Скрипт, согласно критериям оценки, состоит из двух частей:

* поиск упоминаний в базе данных
* поиск упоминаний файла в исходном коде сайта

Установка окружения:
```sh
#!/bin/sh
```
Указание начальной директории сканирования. Это то место, в которое загружаются всей файлы сайта. По умолчанию это путь sites/default/files. Для уточнения пути, зайдите в панель управления сайта на Drupal, перейдите на страницу Конфигурация - Файловая система. Адрес указан в первом поле с именем “Общедоступный путь файловой системы”:
```sh
START=./sites/default/files
```
Установка текущего расположения файла, содержащего этого код:
```sh
CURDIR=`pwd`
```
Игнорирование директории, в которой генерируются картинки:
```sh
IG_STYLES=./styles/*
```
Игнорирование директории, в которой генерируются файлы js:
```sh
IG_JS=./js/*
```
Игнорирование директории, в которой генерируются файлы css:
```sh
IG_CSS=./css/*
```
Указание дампа базы данных:
```sh
dbdump=`pwd`/dumpwebsite.sql
```
Указание файла со списком используемых файлов на сайте:
```sh
usedfile=`pwd`/output_used.txt
```
Указание файла со списком, которые не найдены в базе данных:
```sh
notusedfile=`pwd`/output_notused.txt
```
А это те файлы, которые можно смело удалять:
```sh
notusedfile_check=`pwd`/output_notused_check.txt
```
Переход в точку старта сканирования:
```sh
cd ${START}
```
Вывод сообщение о начале первого шага поиска:
```sh
echo "Step 1. Checking for used and unused files to database..."
```
Вывод даты и времени старта первого шага:
```sh
echo "$(date) $line"
```
Цикл поиска файлов по первому критерию. Устанавливаются директории для игнорирования, в именах файлах пробелы заменяются на “#}”.
Внутри цикла имена файлов приводятся к первоначальному виду и имя файла ищется в дампе базы данных. Если файл найден, то его путь записывается в файл output_used.txt, иначе - в файл output_notused.txt":
```sh
for file in `find . ! -path "$IG_JS" ! -path "$IG_CSS" ! -path "$IG_STYLES" -type f -print | cut -c 3- | sed 's/ /#}/g'`
do
  file2=`echo $file | sed 's/#}/ /g'`
  file3=`basename $file2`
  result=`grep -c "$file3" $dbdump`
  if [ $result = 0 ]; then
    echo $file2 >> $notusedfile
  else
    echo $file2 >> $usedfile
  fi
done
```
Происходит переход в корневую директорию сайта:
```sh
cd ${CURDIR}
```
Вывод сообщение о начале второго шага:
```sh
echo "Step 2. Checking files from list not used files..."
```
Вывод даты и времени старта второго шага:
```sh
echo "$(date) $line"
```
Выполняется цикл, в котором происходит поиск файлов из списка output_notused.txt. Если файл находится то он выводится в пустое устройство /dev/null, иначе - записывается в файл output_notused_check.txt:
```sh
for p in $(cat $notusedfile); do
  grep -rnw --include=*.{module,inc,php,js,css,html,htm} ${CURDIR} -e $p  > /dev/null || echo $p >> $notusedfile_check;
done
Вывод сообщения о завершении поиска
echo "Files checking done."
echo "Check the following text-file for results:"
Вывод файла с конечными результатами
echo "$notusedfile_check"
```
В файле output_notused_check.txt находятся файлы, готовые к удалению.
Скопируйте этот файл в директорию старта сканирования. В нашем примере это sites/default/files.

Перейдите в ту же директорию и выполните команду:
```sh
xargs rm -fr < output_notused_check.txt
```
Здесь происходит удаление файлов из файла output_notused_check.txt

После удаления зайдите на сайт и убедитесь, что все изображения загружаются и отображаются.
Далее перейдите в корень сайта и удалите файлы: dumpwebsite.sql, output_used.txt, output_notused.txt и output_notused_check.txt.

Удачного поиска!
