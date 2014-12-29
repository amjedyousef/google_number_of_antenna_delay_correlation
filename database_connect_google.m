function [response,delay,error]=database_connect_google(request_type,latitude,...
    longitude,height,agl,my_path,counter)

error=false; %Default error value
delay=[]; %Default delay value

server_name='https://www.googleapis.com/rpc';
text_coding='"Content-Type: application/json; charset=utf-8"';

device_type='"MODE_2"'; %Types of TVWS device: http://en.wikipedia.org/wiki/TV-band_device

%%
%API selection
key='"AIzaSyB8381uDKPa00m35QvxOAuge7yprCgMcRU"'
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