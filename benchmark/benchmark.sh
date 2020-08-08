#! /bin/bash --login

set -e

script_name=$1

declare -a RUBIES=( "2.4.9" "2.6.6" "2.7.1" "2.8.0-dev"  "truffleruby-20.1.0" "truffleruby-1.0.0-rc16")

for ruby in "${RUBIES[@]}"
do
  echo Running $ruby
  asdf local ruby $ruby
  ruby -v
  ruby $script_name
  echo
  echo "--------------------------------------------------"
  echo
done

echo "-------------------------------------------"
echo "|            DONE WITH 'NORMAL' RUBIES     |"
echo "-------------------------------------------"

declare -a MJITRUBIES=( "2.6.6" "2.7.1" "2.8.0-dev" )

for ruby in "${MJITRUBIES[@]}"
do
  echo Running $ruby
  asdf local ruby $ruby
  ruby -v
  ruby --jit $script_name
  echo
  echo "--------------------------------------------------"
  echo
done

echo "-------------------------------------------"
echo "|             DONE WITH MJIT RUBIES         |"
echo "-------------------------------------------"

declare -a JRUBIES=("jruby-9.1.17.0" "jruby-9.2.11.1")
declare -a JAVAS=( "adoptopenjdk-8.0.265+1" "adoptopenjdk-8.0.265+1.openj9-0.21.0" "adoptopenjdk-14.0.2+12" "adoptopenjdk-14.0.2+12.openj9-0.21.0" "java-se-ri-8u41-b04" "java-se-ri-14+36" "corretto-8.265.01.1" "corretto-11.0.8.10.1" "dragonwell-8.4.4" "dragonwell-11.0.7.2+9" "graalvm-20.1.0+java8" "graalvm-20.1.0+java11")

for java in "${JAVAS[@]}"
do
  echo "Using Java $java"
  asdf local java $java
  java -version

  for ruby in "${JRUBIES[@]}"
  do
    asdf local ruby $ruby
    echo Running $ruby
    ruby -v
    ruby $script_name
    echo

    echo Running $ruby with --server -Xcompile.invokedynamic=true -J-Xmx1500m
    ruby --server -Xcompile.invokedynamic=true -J-Xmx1500m $script_name
    echo
    echo "--------------------------------------------------"
    echo
  done
  echo "-"
  echo
  echo
done

echo "-------------------------------------------"
echo "|             DONE WITH JRUBIES          |"
echo "-------------------------------------------"

asdf local ruby trufflerubyVM
echo "Running GraalVM installed ruby --native"
ruby --native -v
ruby --native $script_name
echo

echo "Running GraalVM installed ruby --jvm"
ruby --jvm -v
ruby --jvm $script_name
echo
