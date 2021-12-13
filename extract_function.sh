
#
# License
#
# GNU Affero General Public License Version 3.0, https://www.gnu.org/licenses/agpl-3.0.en.html
#


usage(){
   echo 'harden -d <dynamically linked> -f <files and dirs> -r <files to remove> -u user <files to chown to user>' 
}

create_dir(){
  HARDEN=/tmp/harden
  mkdir -p $HARDEN

  for i in $*
  do
    DIR=$HARDEN/$(dirname $i)
   
    mkdir -p "$DIR"
    cp -a "$i" $HARDEN/$i 
    

  done
}

next_section(){
  [ $# -gt 0 ] && [ `echo $1 | head -c 1` != '-' ] && return 0
  return 1
}

ldd_filter(){
  sed 's+\t*++' |\
  sed 's+.*=>\ ++' |\
  sed 's+\ .*$++'
}

link_filter(){
  for f in $(find "$1")
  do
    echo $f
    if [ -L $f ] 
      then
        LINK=$(readlink $f) 
        if [ `echo $LINK | head -c 1` = '/' ]
        then
          echo $LINK
        else
          echo $(dirname $f)/$(readlink $f)
        fi
     fi
   done
}


extract(){

  while [ $# -ne 0 ]
  do	  
    case $1 in
    -x) # enable debugging

      set -x 
      shift
      ;;

    -d)     # dynamically linked executables
    
      shift
      if next_section $*
      then
        for f in $(ldd "$1" | ldd_filter) $1
        do
          link_filter $f
        done
        shift
      fi
      ;;

    -f) # files and links
    
      shift
      while next_section $*
      do
        link_filter $1
        shift
      done
      ;;

    -r) # files to remove
      shift
      while next_section $*
      do
        rm $1
        shift
      done
      ;;

    -u)  # change owner and grand access    
      shift
      OWNER=$1
      shift
      while next_section $*
      do
        chown $OWNER $1
        chmod -R +rw $1
        shift
      done
      ;;
    
    *) # error, show usage 
    
      usage
      exit 1
      ;;
    esac
  done  | uniq | sed 's+^/++'
}

if $0="harden"
then
  extract $*
fi