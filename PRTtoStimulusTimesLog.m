function LogTimesSess=PRTtoStimulusTimesLog(pathOfPRTs) 
% This function reads the PRT files of the approach avoid log
% and arranges them in matlab structure
d=dir([pathOfPRTs '\*.prt']);
for sess=1:length(d);
    
    
        fid=fopen([pathOfPRTs '\' d(sess).name ]);
        sessN=str2num(d(sess).name(end-4)); % assumes that the last letter of the file name represents the sesssion number
        CondsFound=0;
        AvoidNoRisk=[];
        ApproachNoRisk=[];
        AvoidRisk=[];
        ApproachRisk=[];
        while (1)
            line = fgetl(fid); % read line
            if ~ischar(line)
                break;
            else

                K = findstr(line,'Avoidance no risk')
                if length(K)>0 % if the line contains the text Avoidance no risk
                    CondsFound=1;
                    finished=0;
                    line = fgetl(fid);
                    while ~finished % continue to read lines until you find the text Color which signifies that you finnished running on all events of his condition
                        line = fgetl(fid);
                        K2 = findstr(line,'Color');
                        if length(K2)>0
                            finished=1;
                        else
                            spaceInd=regexp(line, ' '); % look for the space that seperates the beggining time from the end time
                            AvoidNoRisk=[AvoidNoRisk; str2num(line(1:spaceInd-1)) str2num(line(spaceInd+1:end))]; % add these times as a new line to the relevant matrix
                        end;
                    end;
                end;
                K = findstr(line,'Approach no risk')
                if length(K)>0
                    CondsFound=2;
                    finished=0;
                    line = fgetl(fid);
                    while ~finished
                        line = fgetl(fid);
                        K2 = findstr(line,'Color');
                        if length(K2)>0
                            finished=1;
                        else
                            spaceInd=regexp(line, ' ');
                            ApproachNoRisk=[ApproachNoRisk; str2num(line(1:spaceInd-1)) str2num(line(spaceInd+1:end))];
                        end;
                    end;
                end;
                K = findstr(line,'Avoidance risk')
                if length(K)>0
                    CondsFound=3;
                    finished=0;
                    line = fgetl(fid);
                    while ~finished
                        line = fgetl(fid);
                        K2 = findstr(line,'Color');
                        if length(K2)>0
                            finished=1;
                        else
                            spaceInd=regexp(line, ' ');
                            AvoidRisk=[AvoidRisk; str2num(line(1:spaceInd-1)) str2num(line(spaceInd+1:end))];
                        end;
                    end;
                end;
                K = findstr(line,'Approach risk')
                if length(K)>0
                    CondsFound=4;
                    finished=0;
                    line = fgetl(fid);
                    while ~finished
                        line = fgetl(fid);
                        K2 = findstr(line,'Color');
                        if length(K2)>0
                            finished=1;
                        else
                            spaceInd=regexp(line, ' ');
                            ApproachRisk=[ApproachRisk; str2num(line(1:spaceInd-1)) str2num(line(spaceInd+1:end))];
                        end;
                    end;
                end;




            end
        end
        fclose(fid);
        LogTimesSess(sessN).AvoidNoRisk=AvoidNoRisk;
        LogTimesSess(sessN).ApproachNoRisk=ApproachNoRisk;
        LogTimesSess(sessN).AvoidRisk=AvoidRisk;
        LogTimesSess(sessN).ApproachRisk=ApproachRisk;
        save([pathOfPRTs '\LogTimesSessApAv.mat'],'LogTimesSess');
end;