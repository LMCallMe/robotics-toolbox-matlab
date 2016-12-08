Installation:
------------

simply copy all the .m files into a directory 'robot' 

add the directory robot to your MATLABPATH

start MATLAB

>> startup_rvc

Help:
----

1: manual

robot.pdf is the documentation in standard Mathworks style.  It is
formatted for double sided printing which makes for a more compact
manual and saves trees.

2: desktop help GUI
from the Matlab desktop, choose help, and select the Robotics Toolbox
option.  HTML format documentation for all functions is available.

3: command line
use the help command from the command prompt, eg. help ikine

4: the web

http://www.petercorke.com/RTB/r9/html


Demos:
-----


2: desktop menu bar
from the menu bar choose demos, and select the Robotics Toolbox

3: command prompt
    >> rtbdemos


Online resources:
----------------

Home page:         http://www.petercorke.com
Discussion group:  http://groups.google.com/group/robotics-tool-box?hl=en
Manual pages:      http://www.petercorke.com/RTB/r9/html

Please email bug reports, comments or code contribtions to me at rvc@petercorke.com

                                                            Peter Corke	
# lmcallme:

## install virtualenv, virtualenvwrapper:

``` shell
$ pip install virtualenv
$ pip install virtualenvwrapper # linux
$ pip install virtualenvwrapper-win # windows

```

when on Linux, put into ~/.bashrc:

``` shell
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
export VIRTUALENVWRAPPER_SCRIPT=/usr/local/bin/virtualenvwrapper.sh
source /usr/local/bin/virtualenvwrapper_lazy.sh
```

## setup

### make env

``` shell
$ mkvirtualenv matlab
```

### use env

``` shell
$ workon matlab
```

### install jupyter notebook

``` shell
$ pip install -r requirements.txt
$ python -m matlab_kernel install # install matlab_kernel for notebook
```

### use jupyter notebook

Windows:

``` shell
$ set MATLAB_EXECUTABLE="C:\Program Files\MATLAB\R2014a\bin\matlab.exe"
$ jupyter notebook
```

Linux:

``` shell
$ export MATLAB_EXECUTABLE=/Applications/MATLAB_2015b.app/bin/matlab
$ jupyter notebook
```