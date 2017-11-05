#! /bin/bash 

 ## find the bash version
 bash --version | grep "bash" | head -n1
 ## Declare normal variables 
name="chenna"
age=29
echo my name is $name and $age
  ## Decleare variables with declare or typeset
declare -r name
echo $name
declare -r age
(( age++))
# error age readonly variable
  ## integer varibules with declare -i
declare -i name
echo $name
# error 
declare -i int
int=6/2
echo $int
  ## array variables with decleare -a

array1=(0 1 2 3 4 5 6 7 8 9)
#array2=1
declare -a array1
echo $array1

  ## declare -f Functio_name
func1 ()
{
declare -x name
echo $name
echo name
}
declare -f func1
  ## declare -x This declares a variable as available for exporting outside the environment of the script itself.
	
