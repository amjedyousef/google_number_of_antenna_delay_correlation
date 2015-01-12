function [response,delay,error]=database_connect_google(request_type,latitude,...
    longitude,height,agl,my_path,counter)
% This function query google WSDB.
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

error=false; %Default error value
delay=[]; %Default delay value

server_name='https://www.googleapis.com/rpc';
text_coding='"Content-Type: application/json; charset=utf-8"';

device_type='"MODE_2"'; %Types of TVWS device: http://en.wikipedia.org/wiki/TV-band_device

%%
%API selection
if counter<1e3
    fprintf('key 1\n');
    key='"AIzaSyB8381uDKPa00m35QvxOAuge7yprCgMcRU"'; %API [replace by your own]
elseif 1e3<=counter && counter<2e3
    fprintf('key 2\n');
    key='"AIzaSyB8381uDKPa00m35QvxOAuge7yprCgMcRU"'; %API [replace by your own]
end
%%

google_query(request_type,device_type,latitude,longitude,height,agl,key);

my_path=regexprep(my_path,' ','\\ ');

cmnd=['/usr/bin/curl -X POST ',server_name,' -H ',text_coding,' --data-binary @',my_path,'/google.json -w %{time_total}'];
[status,response]=system(cmnd);

%check for error
err = findstr('error' , response);
if ~isempty(err)
    error = true;
end


warning_google='Daily Limit Exceeded'; %Error handling in case of exceeed API limit

if ~isempty(findstr(response,warning_google));
    fprintf('API limit exceeded - quitting.\n');
    return;
else
    end_query_str='"FccTvBandWhiteSpace-2010"';
    
    response = response(findstr(response , '{'):end);
    pos_end_query_str=findstr(response,end_query_str);
    
    pos_end_query_str=findstr(response,end_query_str);
    length_end_query_str=length(end_query_str)+14; %Note: constant 14 added due to padding of '}' in JSON response
    response(pos_end_query_str+length_end_query_str:end);
    delay=str2num(response(pos_end_query_str+length_end_query_str:end));
    response(pos_end_query_str+length_end_query_str:end)=[];
end
system('rm google.json');

function google_query(request_type,device_type,latitude,longitude,height,agl,key)

request=['{"jsonrpc": "2.0",',...
    '"method": "spectrum.paws.getSpectrum",',...
    '"apiVersion": "v1explorer",',...
    '"params": {',...
    '"type": ',request_type,', ',...
    '"version": "1.0", ',...
    '"deviceDesc": ',...
    '{ "serialNumber": "your_serial_number", ',...
    '"fccId": "TEST", ',... %21 June 2014: fix to FCC's "OPSXX ids" case: replace "OPS13" with "TEST" [https://groups.google.com/forum/#!topic/google-spectrum-db-discuss/qitm_hgbw4A]
    '"fccTvbdDeviceType": ',device_type,' }, ',...
    '"location": ',...
    '{ "point": ',...
    '{ "center": ',...
    '{"latitude": ',latitude,', '...
    '"longitude": ',longitude,'} } },',...
    '"antenna": ',...
    '{ "height": ',height,', ',...
    '"heightType": ',agl,' },',...
    '"owner": { "owner": { } }, ',...
    '"capabilities": { "frequencyRanges": [{ "startHz": 800000000, "stopHz": 850000000 }, { "startHz": 900000000, "stopHz": 950000000 }] }, ',...
    '"key": ',key,...
    '},"id": "any_string"}'];

dlmwrite('google.json',request,'');