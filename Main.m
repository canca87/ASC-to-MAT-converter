% This script will convert all ASC files in the directory to MAT files.
% The ASC files contain 3D data from the Bruker Optical Profiler in the 
% form of three column vectors. Vectors 1 and 2 are the X and Y location
% while column three contains the height in NANOMETERS.

% The header of the file provides valuable information and will be stored
% in a struct for later extraction.

%% -Clears everything up to make sure there will be no conflicting variables
clear all; %clears all variables
clc; %clears the console

%% -Searches the current directory for all ASC files and generates a file list
% only this directory, no subdirectories.
files = dir('*.ASC');
files = files(~[files.isdir]);
files = {files.name}.';
nf = numel(files);
for n = 1:nf
    current_filename = files{n};

    %% -Opens a file, imports the data to 'c' and closes the file
    fid = fopen(current_filename); %opens the current file
    fmt=repmat('%s',1,6); %its acutally only 4 columns, but i got a buffer here
    c=textscan(fid,fmt,'delimiter','\t','collectoutput',true);
    fid=fclose(fid); %closes the file
    clear('fid','fmt')

    %% -Read the cell line by line.
    clear('s','items','i','name')
    s = struct;

    for i = 1:4
        %checking for special cases - Always present headers -
        if not(isempty(strfind('Wyko',c{:}{i,1})))
        %Title. This can be ignored.
        end
        if not(isempty(strfind('X Size',c{:}{i,1})))
        %X size of the data. Store in struct
        name = c{:}{i,1};
        name = regexprep(name,' ','_');
        s.(name) = str2double(c{:}{i,2});
        end
        if not(isempty(strfind('Y Size',c{:}{i,1})))
        %Y size of the data. Store in struct
        name = c{:}{i,1};
        name = regexprep(name,' ','_');
        s.(name) = str2double(c{:}{i,2});
        end
        if not(isempty(strfind('Block Name',c{:}{i,1})))
        %This is the title of the main data table - column headers.
        items = size(c{:}) - 4; %this is how many data lines are left to process
        for line = 5:items(1) %each line
            %check if it is a number (data) or a string (new variable)
            [~,isNumeric] = str2num(c{:}{line,1});
            if isNumeric
                %its a number, ignore it (something went wrong??)
            else
                %its a header, process the next one to determine its type
                [num,isNumeric] = str2num(c{:}{line,2});
                if isNumeric
                    %types I know of can be 7,8 or 3.
                    if num == 7 %7 is a standard value.
                        name = c{:}{line,1};
                        name = regexprep(name,' ','_');
                        s.(name) = str2num(c{:}{line,4});
                    elseif num == 8 %8 is a standard value.
                        name = c{:}{line,1};
                        name = regexprep(name,' ','_');
                        s.(name) = str2num(c{:}{line,4});
                    elseif num == 3 %Three is a data array
                        %Generate an array of data from this block
                        res = 0; %default data.

                        %looping through all the data
                        for cellValue = line+1:items(1)
                            [num,isNumeric] = str2num(c{:}{cellValue,1});
                            if isNumeric
                                row = str2double(c{:}{cellValue,1}) + 1;
                                col = str2double(c{:}{cellValue,2}) + 1;
                                tval = c{:}{cellValue,3};
                                if length(tval) == 4
                                    isbad = tval == 'Bad ';
                                else
                                    isbad(1) = 0;
                                end
                                if isbad(1) == 1
                                    res(row,col) = NaN;
                                else
                                    res(row,col) = str2num(tval);
                                end 
                            else
                                break; %The first column has encountered a string.
                                %exit the for look, the data array is complete.
                            end
                        end

                        %data collected. Store it in the structure and delete
                        name = c{:}{line,1};
                        name = regexprep(name,' ','_');
                        s.(name) = res;

                        clear('res','isbad','tval','row','col','cellValue')
                    else
                        %unknown data type. Leave it and move on
                    end
                end
            end
        end
        end
    end
    clear('i','isNumeric','num','name','line','items','c')

    %The only thing left should be structe 's', and the filenames.
    %% Save back to a MAT file with the same name
    save(regexprep(current_filename,'.ASC','.mat'),'s');
    clear('s')
end
clear('current_filename','files','n','nf')