% Brick Interface to Lego Minstorms EV3 brick
%
% Methods::
% brick              Constructor, establishes communications
% delete             Destructor, closes connection
% send               Send data to the brick
% receive            Receive data from the brick
% 
% uiReadVBatt        Returns battery level as a voltage
% uiReadLBatt        Returns battery level as a percentage
%
% playTone           Plays a tone at a volume with a frequency and duration
% beep               Plays a beep tone with volume and duration
% playThreeTone      Plays three tones one after the other
%
% inputDeviceGetName Return the device name at a layer and NO
% inputDeviceSymbol  Return the symbol for the device at a layer, NO and mode
% inputDeviceClrAll  Clear all the sensor data at a layer
% inputReadSI        Reads a connected sensor at a layer, NO, type and mode in SI units
% plotSensor         Plots a sensor readings over time
%
% outputStop         Stops motor at a layer, NOS and brake
% outputPower        Sets motor output power at a layer, NOS and speed
% outputStart        Starts motor at a layer, NOS and speed
% outputStepSpeed    Moves a motor to set position with layer, NOS, speed, ramp up angle, constant angle, ramp down angle and brake
% outputClrCount     Clears a motor tachometer at a  layer and NOS
% outputGetCount     Returns the tachometer at a layer and NOS
%
% fileUpload         Upload a file to the brick
% fileDownload       Download a file from the brick
% listFiles          List files on the brick from a directory  
% createDir          Create a directory on the brick
% deleteFile         Delete a file from the brick
%
% threeToneByteCode  Generate the bytecode for the playThreeTone function 
%
% Example::
%           b = Brick('ioType','usb')
%           b = Brick('ioType','wifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
%           b = Brick('ioType','bt','serPort','/dev/rfcomm0')

classdef Brick < handle
    
    properties
        % connection handle
        conn;
        % debug input
        debug;
        % IO connection type
        ioType;
        % bluetooth brick device name
        btDevice;
        % bluetooth brick communication channel
        btChannel;
        % wifi brick IP address
        wfAddr;
        % wifi brick TCP port
        wfPort; 
        % brick serial number
        wfSN; 
        % bluetooth serial port
        serPort;
    end

    methods
        function brick = Brick(varargin) 
             % Brick.Brick Create a Brick object
             %
             % b = Brick(OPTIONS) is an object that represents a connection
             % interface to a Lego Mindstorms EV3 brick.
             %
             % Options::
             %  'debug',D       Debug level, show communications packet
             %  'ioType',P      IO connection type, either usb, wifi or bt
             %  'btDevice',bt   Bluetooth brick device name
             %  'btChannel',cl  Bluetooth connection channel
             %  'wfAddr',wa     Wifi brick IP address
             %  'wfPort',pr     Wifi brick TCP port, default 5555
             %  'wfSN',sn       Wifi brick serial number (found under Brick info on the brick OR through sniffing the UDP packets the brick emits on port 3015)
             %  'serPort',SP    Serial port connection
             %
             % Notes::
             % - Can connect through: usbBrickIO, wfBrickIO, btBrickIO or
             % instrBrickIO.
             % - For usbBrickIO:
             %      b = Brick('ioType','usb')
             % - For wfBrickIO:
             %      b = Brick('ioType','wifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
             % - For btBrickIO:
             %      b = Brick('ioType','bt','serPort','/dev/rfcomm0')
             % - For instrBrickIO (wifi)
             %      b = Brick('ioType',instrwifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
             % - For instrBrickIO (bluetooth)
             %      b = Brick('ioType',instrbt','btDevice','EV3','btChannel',1)
             
             % init the properties
             opt.debug = 0;
             opt.btDevice = 'EV3';
             opt.btChannel = 1;
             opt.wfAddr = '192.168.1.104';
             opt.wfPort = 5555;
             opt.wfSN = '0016533dbaf5';
             opt.ioType = 'usb';
             opt.serPort = '/dev/rfcomm0';
             % read in the options
             opt = tb_optparse(opt, varargin);
             % select the connection interface
             connect = 0;
             % usb
             if(strcmp(opt.ioType,'usb'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.conn = usbBrickIO(brick.debug);
                connect = 1;
             end
             % wifi
             if(strcmp(opt.ioType,'wifi'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.wfAddr = opt.wfAddr;
                brick.wfPort = opt.wfPort;
                brick.wfSN = opt.wfSN;
                brick.conn = wfBrickIO(brick.debug,brick.wfAddr,brick.wfPort,brick.wfSN);
                connect = 1;
             end
             % bluetooth
             if(strcmp(opt.ioType,'bt'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.serPort = opt.serPort;
                brick.conn = btBrickIO(brick.debug,brick.serPort);
                connect = 1;
             end
             % instrumentation and control wifi 
             if(strcmp(opt.ioType,'instrwifi'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.wfAddr = opt.wfAddr;
                brick.wfPort = opt.wfPort;
                brick.wfSN = opt.wfSN;
                brick.conn = instrBrickIO(brick.debug,brick.wfAddr,brick.wfPort,brick.wfSN);
                connect = 1;
             end
             % instrumentation and control bluetooth 
             if(strcmp(opt.ioType,'instrbt'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.btDevice = opt.btDevice;
                brick.btChannel = opt.btChannel;
                brick.conn = instrBrickIO(brick.debug,brick.btDevice,brick.btChannel);
                connect = 1;
             end
             % error
             if(~connect)
                 fprintf('Please specify a serConn option: ''usb'',''wifi'',''bt'',''instrwifi'' or ''instrbt''.\n');
             end
        end
        
        function delete(brick)
            % Brick.delete Delete the Brick object
            %
            % delete(b) closes the connection to the brick
            
            brick.conn.close();
        end  
        
        function send(brick, cmd)
            % Brick.send Send data to the brick
            %
            % Brick.send(cmd) sends a command to the brick through the
            % connection handle.
            %
            % Notes::
            % - cmd is a command object.
            %
            % Example::
            %           b.send(cmd)
            
            % send the message through the brickIO write function
            brick.conn.write(cmd.msg);
            if brick.debug > 0
               fprintf('sent:    [ ');
               for ii=1:length(cmd.msg)
                   fprintf('%d ',cmd.msg(ii))
               end
               fprintf(']\n');
            end
        end
       
        function rmsg = receive(brick)
            % Brick.receive Receive data from the brick
            %
            % rmsg = Brick.receive() receives data from the brick through
            % the connection handle.
            %
            % Example::
            %           rmsg = b.receive()
 
            % read the message through the brickIO read function
            rmsg = brick.conn.read();
            if brick.debug > 0
               fprintf('received:    [ ');
               for ii=1:length(rmsg)
                   fprintf('%d ',rmsg(ii))
               end
               fprintf(']\n');
            end
        end
        
        function voltage = uiReadVbatt(brick)
            % Brick.uiReadVbatt Return battery level (voltage)
            % 
            % voltage = uiReadVbatt returns battery level as a voltage.
            %
            % Example::
            %           voltage = b.uiReadVbatt()
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            cmd.opUI_READ_GET_VBATT(0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            voltage = typecast(uint8(msg(6:9)),'single');           
            if brick.debug > 0
                fprintf('Battery voltage: %.02fV\n', voltage);
            end
        end
        
        function level = uiReadLbatt(brick)
            % Brick.uiReadLbatt Return battery level (percentage)
            % 
            % level = Brick.uiReadLbatt() returns battery level as a
            % percentage from 0 to 100%.
            %
            % Example::
            %           level = b.uiReadLbatt()
          
            cmd = Command();
            cmd.addHeaderDirectReply(42,1,0);
            cmd.opUI_READ_GET_LBATT(0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            level = msg(6);
            if brick.debug > 0
                fprintf('Battery level: %d%%\n', level);
            end
        end
        
        function playTone(brick, volume, frequency, duration)  
            % Brick.playTone Play a tone on the brick
            %
            % Brick.playTone(volume,frequency,duration) plays a tone at a
            % volume, frequency and duration.
            %
            % Notes::
            % - volume is the tone volume from 0 to 100.
            % - frequency is the tone frequency in Hz.
            % - duration is the tone duration in ms.
            %
            % Example:: 
            %           b.playTone(5,400,500)

            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opSOUND_TONE(volume,frequency,duration);
            cmd.addLength();
            brick.send(cmd);
        end
                 
        function beep(brick,volume,duration)
            % Brick.beep Play a beep on the brick
            %
            % Brick.beep(volume,duration) plays a beep tone with volume and
            % duration.
            %
            % Notes::
            % - volume is the beep volume from 0 to 100.
            % - duration is the beep duration in ms.
            %
            % Example:: 
            %           b.beep(5,500)
            
            if nargin < 2
                volume = 10;
            end
            if nargin < 3
                duration = 100;
            end
            brick.playTone(volume, 1000, duration);
        end
        
        function playThreeTones(brick)
            % Brick.playThreeTones Play three tones on the brick
            %
            % Brick.playThreeTones() plays three tones consequentively on
            % the brick with one upload command.
            %
            % Example::
            %           cmd.playThreeTones();
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opSOUND_TONE(5,440,500);
            cmd.opSOUND_READY();
            cmd.opSOUND_TONE(10,880,500);
            cmd.opSOUND_READY();
            cmd.opSOUND_TONE(15,1320,500);
            cmd.opSOUND_READY();
            cmd.addLength();
            % print message
            fprintf('Sending three tone message ...\n');
            brick.send(cmd);    
        end
        
        function name = inputDeviceGetName(brick,layer,no)
            % Brick.inputDeviceGetName Get the input device name
            %
            % Brick.inputDeviceGetName(layer,no) returns the name of the
            % device connected where 'name' is the devicetype-devicemode.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            %
            % Example::
            %           name = b.inputDeviceGetName(0,Device.Port1)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,12,0);
            cmd.opINPUT_DEVICE_GET_NAME(layer,no,12,0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            % return the device name
            name = sscanf(char(msg(6:end)),'%s');
        end
        
        function name = inputDeviceSymbol(brick,layer,no)
            % Brick.inputDeviceSymbol Get the input device symbol
            %
            % Brick.inputDeviceSymbol(layer,no) returns the symbol used for
            % the device in it's current mode.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            %
            % Example::
            %           name = b.inputDeviceGetName(0,Device.Port1)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,5,0);
            cmd.opINPUT_DEVICE_GET_SYMBOL(layer,no,5,0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            % return the symbol name
            name = sscanf(char(msg(6:end)),'%s');
        end
        
        function inputDeviceClrAll(brick,layer)
            % Brick.inputDeviceClrAll Clear the sensors
            %
            % Brick.inputDeviceClrAll(layer) clears the sensors connected
            % to layetr.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            %
            % Example::
            %           name = b.inputDeviceClrAll(0)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,5,0);
            cmd.opINPUT_DEVICE_CLR_ALL(layer);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function reading = inputReadSI(brick,layer,no,mode)
            % Brick.inputReadSI(brick,layer,no,type,mode) Input read (SI)
            % 
            % reading = Brick.inputReadSI(brick,layer,no,type,mode) reads a 
            % connected sensor at a layer, NO, type and mode in SI units.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            % - mode is the sensor mode from types.html. (-1=dont' change)
            % - returned reading is DATAF.
            %
            % Example::
            %            reading = b.inputReadSI(0,Device.Port1,Device.USDistCM)
            %            reading = b.inputReadSI(0,Device.Port1,Device.Pushed)
           
            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            cmd.opINPUT_READSI(layer,no,0,mode,0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            reading = typecast(uint8(msg(6:9)),'single');
            if brick.debug > 0
                 fprintf('Sensor reading: %.02f\n', reading);
            end
        end
        
        function plotSensor(brick,layer,no,mode)
            % Brick.plotSensor plot the sensor output 
            %
            % Brick.plotSensor(layer,no,type,mode) plots the sensor output
            % to MATLAB. 
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            % - mode is the sensor mode from types.html. (-1=don't change)
            %
            % Example::
            %           b.plotSensor(0,Device.Port1,Device.USDistCM)
            %           b.plotSensor(0,Device.Port1,Device.GyroAng)
            
            % start timing
            tic;
            % create figure
            hfig = figure('name','EV3 Sensor');
            % init the the data
            t = 0;
            x = 0;
            hplot = plot(t,x);
            % one read to set the mode
            reading = brick.inputReadSI(layer,no,mode);
            % set the title
            name = brick.inputDeviceGetName(layer,no);
            title(['Device name: ' name]);
            % set the y label
            name = brick.inputDeviceSymbol(layer,no);
            ylabel(['Sensor value (' name(1:end-1) ')']);
            % set the x label
            xlabel('Time (s)');
            % set the x axis
            xlim([0 10]);
            % wait until the figure is closed
            while(findobj('name','EV3 Sensor') == 1)
                % get the reading
                reading = brick.inputReadSI(layer,no,mode);
                t = [t toc];
                x = [x reading];
                set(hplot,'Xdata',t)
                set(hplot,'Ydata',x)
                drawnow
                % reset after 10 seconds
                if (toc > 10)
                   % reset
                   t = 0;
                   x = x(end);
                   tic
                end
            end
        end
            
        
        function outputStop(brick,layer,nos,brake)
            % Brick.outputPower Stops a motor
            %
            % Brick.outputPower(layer,nos,brake) stops motor at a layer 
            % NOS and brake.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - brake is [0..1] (0=Coast,  1=Brake).
            %
            % Example::
            %           b.outputStop(0,Device.MotorA,Device.Brake)
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STOP(layer,nos,brake)
            cmd.addLength();
            brick.send(cmd);
        end
        
        function outputStopAll(brick)
            % Brick.outputStopAll Stops all motors
            %
            % Brick.outputStopAll(layer) stops all motors on layer 0.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - Sends 0x0F as the NOS bit field to stop all motors.
            %
            % Example::
            %           b.outputStopAll(0)
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STOP(0,15,Device.Brake);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function outputPower(brick,layer,nos,power)
            % Brick.outputPower Set the motor output power
            % 
            % Brick.outputPower(layer,nos,power) sets motor output power at
            % a layer, NOS and power.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - power is the output power with [+-0..100%] range.
            %
            % Example::
            %           b.outputPower(0,Device.MotorA,50)
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_POWER(layer,nos,power);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function outputStart(brick,layer,nos)
            % Brick.outputStart Starts a motor
            %
            % Brick.outputStart(layer,nos) starts a motor at a layer and
            % NOS.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            %
            % Example::
            %           b.outputStart(0,Device.MotorA)
          
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_START(layer,nos);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function outputStepSpeed(brick,layer,nos,speed,step1,step2,step3,brake)
            % 
            %
            % Brick.outputStepSpeed(layer,nos,speed,step1,step2,step3,brake)
            % moves a motor to set position with layer, NOS, speed, ramp up
            % angle, constant angle, ramp down angle and brake.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - speed is the output speed with [+-0..100%] range.
            % - step1 is the steps used to ramp up.
            % - step2 is the steps used for constant speed.
            % - step3 is the steps used for ramp down.
            % - brake is [0..1] (0=Coast,  1=Brake).
            % Example::
            %           b.outputStepSpeed(0,Device.MotorA,50,50,360,50,Device.Coast)
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STEP_SPEED(layer,nos,speed,step1,step2,step3,brake);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function outputClrCount(brick,layer,nos)
           % Brick.outputClrCount Clear output count
           % 
           % Brick.outputClrCount(layer,nos) clears a motor tachometer at a
           % layer and NOS.
           %
           % Notes::
           % - layer is the usb chain layer (usually 0).
           % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
           %
           % Example::
           %            outputClrCount(0,Device.MotorA)
           
           cmd = Command();
           cmd.addHeaderDirect(42,0,0);
           cmd.opOUTPUT_CLR_COUNT(layer,nos);
           cmd.addLength();
           brick.send(cmd);
        end
        
        function tacho = outputGetCount(brick,layer,nos)
            % Brick.outputGetCount(layer,nos) Get output count
            % 
            % tacho = Brick.outputGetCount(layer,nos) returns the tachometer 
            % at a layer and NOS.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NOS is output number [0x00..0x0F].
            % - The NOS here is different to the regular NOS, almost an
            % intermediary between NOS and NO.
            %
            % Example::
            %           tacho = b.outputGetCount(0,Device.MotorA)

            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            cmd.opOUTPUT_GET_COUNT(layer,nos-1,0);
            cmd.addLength();
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            tacho = typecast(uint8(msg(6:9)),'uint32');
            if brick.debug > 0
                fprintf('Tacho: %d degrees\n', tacho);
            end
        end       
        
        function fileUpload(brick,filename,dest)
            % Brick.fileUpload Upload a file to the brick
            %
            % Brick.fileUpload(filename,dest) upload a file from the PC to
            % the brick.
            %
            % Notes::
            % - filename is the local PC file name for upload.
            % - dest is the remote destination on the brick relative to the
            % '/home/root/lms2012/sys' directory. Directories are created
            % in the path if they are not present.
            %
            % Example::
            %           b.fileUpload('prg.rbf','../apps/tst/tst.rbf')
            
            fid = fopen(filename,'r');
            % read in the file in and convert to uint8
            input = fread(fid,inf,'uint8=>uint8');
            fclose(fid); 
            % begin upload
            cmd = Command();
            cmd.addHeaderSystemReply(10);
            cmd.BEGIN_DOWNLOAD(length(input),dest);
            cmd.addLength();
            brick.send(cmd);
            % receive the sent response
            rmsg = brick.receive();
            handle = rmsg(end);
            pause(1)
            % send the file
            cmd.clear();
            cmd.addHeaderSystemReply(11);
            cmd.CONTINUE_DOWNLOAD(handle,input);
            cmd.addLength();
            brick.send(cmd);
            % receive the sent response
            rmsg = brick.receive();
            % print message 
            fprintf('%s uploaded\n',filename);
        end
        
        function fileDownload(brick,dest,filename,maxlength)
            % Brick.fileDownload Download a file from the brick
            %
            % Brick.fileDownload(dest,filename,maxlength) downloads a file 
            % from the brick to the PC.
            %
            % Notes::
            % - dest is the remote destination on the brick relative to the
            % '/home/root/lms2012/sys' directory.
            % - filename is the local PC file name for download e.g.
            % 'prg.rbf'.
            % - maxlength is the max buffer size used for download.
            % 
            % Example::
            %           b.fileDownload('../apps/tst/tst.rbf','prg.rbf',59)
            
            % begin download
            cmd = Command();
            cmd.addHeaderSystemReply(12);
            cmd.BEGIN_UPLOAD(maxlength,dest);
            cmd.addLength();
            brick.send(cmd);
            % receive the sent response
            rmsg = brick.receive();
            % extract payload
            payload = rmsg(13:end);
            % print to file
            fid = fopen(filename,'w');
            % read in the file in and convert to uint8
            fwrite(fid,payload,'uint8');
            fclose(fid); 
        end
        
        function listFiles(brick,pathname,maxlength)
            % Brick.listFiles List files on the brick
            %
            % Brick.listFiles(brick,pathname,maxlength) list files in a 
            % given directory.
            %
            % Notes::
            % - pathname is the absolute path required for file listing.
            % - maxlength is the max buffer size used for file listing.
            % - If it is a file:
            %   32 chars (hex) of MD5SUM + space + 8 chars (hex) of filesize + space + filename + new line is returned.
            % - If it is a folder:
            %   foldername + / + new line is returned.
            %
            % Example::
            %           b.listFiles('/home/root/lms2012/',100)
            
            cmd = Command();
            cmd.addHeaderSystemReply(13);
            cmd.LIST_FILES(maxlength,pathname);
            cmd.addLength();
            brick.send(cmd);
            rmsg = brick.receive();
            % print
            fprintf('%s',rmsg(13:end));
        end    
        
        function createDir(brick,pathname)
            % Brick.createDir Create a directory on the brick
            % 
            % Brick.createDir(brick,pathname) creates a diretory on the 
            % brick from the given pathname.
            %
            % Notes::
            % - pathname is the absolute path for directory creation.
            %
            % Example::
            %           b.createDir('/home/root/lms2012/newdir')
            
            cmd = Command();
            cmd.addHeaderSystemReply(14);
            cmd.CREATE_DIR(pathname);
            cmd.addLength();
            brick.send(cmd);
            rmsg = brick.receive();
        end
        
        function deleteFile(brick,pathname)
            % Brick.deleteFile Delete file on the brick
            % 
            % Brick.deleteFile(brick,pathname) deletes a file from the
            % brick with the given pathname. 
            %
            % Notes::
            % - pathname is the absolute file path for deletion.
            % - will only delete files or empty directories.
            %
            % Example::
            %           b.deleteFile('/home/root/lms2012/newdir')
            
            cmd = Command();
            cmd.addHeaderSystemReply(15);
            cmd.DELETE_FILE(pathname);
            cmd.addLength();
            brick.send(cmd);
            rmsg = brick.receive();
        end
        
        function threeToneByteCode(brick,filename)
            % Brick.threeToneByteCode Create three tone byte code
            %
            % Brick.threeToneByteCode() generates the byte code for the
            % play three tone function. This is an example of how byte code
            % can be generated as an rbf value
            %
            % Notes::
            % - filename is the name of the file to store the byte code in
            % (the rbf extension is added to the filename automatically)
            %
            % Example::
            %           b.threeToneByteCode('threetone')
            
            cmd = Command();
            % program header
            cmd.PROGRAMHeader(0,1,0);                   % VersionInfo,NumberOfObjects,GlobalBytes
            cmd.VMTHREADHeader(0,0);                    % OffsetToInstructions,LocalBytes
            % commands                                  % VMTHREAD1{
            cmd.opSOUND_TONE(5,440,500);                % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opSOUND_TONE(10,880,500);               % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opSOUND_TONE(15,1320,500);              % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opOBJECT_END;                           % }
            % add file size in header
            cmd.addFileSize;
            % generate the byte code
            cmd.GenerateByteCode(filename);
        end
    end
end