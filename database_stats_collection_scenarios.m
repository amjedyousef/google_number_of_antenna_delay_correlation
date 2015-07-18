% This script query 10 different locations. Each has a different number of antennas around it.
% Then it plots the response time 
%   Last update: 10 January 2015

% Reference:
%   P. Pawelczak et al. (2014), "Will Dynamic Spectrum Access Drain my
%   Battery?," submitted for publication.

%   Code development: Amjed Yousef Majid (amjadyousefmajid@student.tudelft.nl), 
%                     Przemyslaw Pawelczak (p.pawelczak@tudelft.nl)

% Copyright (c) 2014, Embedded Software Group, Delft University of 
% Technology, The Netherlands. All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
% 
% 3. Neither the name of the copyright holder nor the names of its
% contributors may be used to endorse or promote products derived from this
% software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

tic;
clear;
close all;
clc;
%%
%Create legend for the figures
legend_string={'Google'};
legend_flag=[];
legend_string(find(~legend_flag))=[];
%%
%Plot parameters
ftsz=16;
%%
%Path to save files (select your own)
my_path='/Users/amjed/Desktop/google_number_of_antenna_delay_correlation/data';
%%
%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height='30.0'; %In meters; Note: 'height' needs decimal value
agl='"AMSL"';

no_queries=20; %Select how many queries per location

%Location data
WSDB_data{1}.name='VI-25'; %victorville
WSDB_data{1}.latitude='34.515543';
WSDB_data{1}.longitude='-117.276797';
WSDB_data{1}.delay_google=[];

WSDB_data{2}.name='AL-25'; %Allentown
WSDB_data{2}.latitude='40.603292';
WSDB_data{2}.longitude='-75.478052';
WSDB_data{2}.delay_google=[];

WSDB_data{3}.name='EP-23'; %Ephrata
WSDB_data{3}.latitude='40.172927';
WSDB_data{3}.longitude='-76.172855';
WSDB_data{3}.delay_google=[];

WSDB_data{4}.name='GA-19'; %Gary
WSDB_data{4}.latitude='41.592141';
WSDB_data{4}.longitude='-87.345176';
WSDB_data{4}.delay_google=[];

WSDB_data{5}.name='DA-18'; %Dallas
WSDB_data{5}.latitude='32.781706';
WSDB_data{5}.longitude='-96.805841';
WSDB_data{5}.delay_google=[];

WSDB_data{6}.name='RO-1'; % rock springs
WSDB_data{6}.latitude='41.611674';
WSDB_data{6}.longitude='-109.285132';
WSDB_data{6}.delay_google=[];

WSDB_data{7}.name='NO-3'; %north platte
WSDB_data{7}.latitude='41.124505';
WSDB_data{7}.longitude='-100.776682';
WSDB_data{7}.delay_google=[];

WSDB_data{8}.name='BI-4'; %Billings
WSDB_data{8}.latitude='45.782992';
WSDB_data{8}.longitude='-108.506303';
WSDB_data{8}.delay_google=[];

WSDB_data{9}.name='QU-5'; %Quincy
WSDB_data{9}.latitude='39.935748';
WSDB_data{9}.longitude='-91.409849';
WSDB_data{9}.delay_google=[];

WSDB_data{10}.name='BI-5'; %Bismarck
WSDB_data{10}.latitude='46.797028';
WSDB_data{10}.longitude='-100.778020';
WSDB_data{10}.delay_google=[];


[wsbx,wsby]=size(WSDB_data); %Get location data size

delay_google_vector=[];
legend_label_google=[];

%Initialize Google API request counter [important: it needs initliazed
%manually every time as limit of 1e3 queries per API is enforced. Check
%your Google API console to check how many queries are used already]
ggl_cnt=250;

for ln=1:wsby
    delay_google=[];
    for xx=1:no_queries
        fprintf('[Query no., Location no.]: %d, %d\n',xx,ln)
        
        %Fetch location data
        latitude=WSDB_data{ln}.latitude;
        longitude=WSDB_data{ln}.longitude;
        
        %Query Google
        ggl_cnt=ggl_cnt+1;
        instant_clock=clock; %Start clock again if scanning only one database
        cd(my_path);
        [msg_google,delay_google_tmp,error_google_tmp]=...
            database_connect_google(type,latitude,longitude,height,agl,my_path,ggl_cnt);
        var_name=(['google_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
        if error_google_tmp==0
            dlmwrite([var_name,'.txt'],msg_google,'');
            delay_google=[delay_google,delay_google_tmp];
        end
    end
    
    %Clear old query results
    cd(my_path);
    
    %Save delay data per location
    WSDB_data{ln}.delay_google=delay_google;
    legend_label_google=[legend_label_google,repmat(ln,1,length(delay_google))]; %Label items for boxplot
    delay_google_vector=[delay_google_vector,delay_google];
    labels_google(ln)={WSDB_data{ln}.name};
end

%%
%Plot figure: Box plots for delay per location

%Select maximum Y axis
max_el=max([delay_google_vector(1:end)]);

    figure('Position',[440 378 560/2.5 420/2]);
    
    boxplot(delay_google_vector,legend_label_google,'labels',labels_google,'symbol','g+','jitter',0,'notch','on',...
        'factorseparator',1);
    ylim([0 max_el]);
    set(gca,'FontSize',ftsz);
    ylabel('Response delay (sec)','FontSize',ftsz);
    set(findobj(gca,'Type','text'),'FontSize',ftsz); %Boxplot labels size
    %Move boxplot labels below to avoid overlap with x axis
    txt=findobj(gca,'Type','text');
    set(txt,'VerticalAlignment','Top');

%%
save('number-of-antenna-delay-correlation');
['Elapsed time: ',num2str(toc/60),' min']