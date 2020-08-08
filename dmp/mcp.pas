(****************************************************************************

                                   MCP.PAS
                                   -------

                          (C) 1993 Jussi Lahdenniemi

Turbo/Borland pascal unit header file for MCP.
Original C header by Otto Chrons

****************************************************************************)

Unit MCP;
{$F+,R-}

Interface
uses CDI;

Type PSampleinfo        = ^TSampleInfo;
     TSampleInfo        = Record
                            Sample      : Pointer;
                            Length,
                            Loopstart,
                            Loopend     : Longint;
                            Mode        : Byte;
                            SampleID    : Word;
                          End;

      PSoundCard        = ^TSoundCard;
      TSoundCard        = Record
                            ID          : Byte;
                            version     : Word;
                            name        : Array[0..31] of char;
                            IOPort      : Word;
                            dmaIRQ      : Byte;
                            dmaChannel  : Byte;
                            minRate     : Word;
                            maxRate     : Word;
                            Stereo      : Boolean;
                            mixer       : Boolean;
                            sampleSize  : Byte;
                            extraField  : array[0..7] of byte;
                          End;

      TSoundDevice      = Record
                            InitDevice,
                            InitOutput,
                            InitRate,
                            CloseDevice,
                            CloseOutput,
                            StopOutput,
                            PauseOutput,
                            ResumeOutput,
                            GetBufferPos,
                            SpeakerOn,
                            SpeakerOff  : Pointer;
                          End;

      PMCPstruct        = ^TMCPstruct;
      TMCPstruct        = Record
                            SamplingRate: Word;
                            Options     : Word;
                            bufferSeg   : Word;
                            bufferLinear: Longint;
                            bufferSize  : Word;
                            reqSize     : Word;
                          End;

      PMCPoutput        = ^TMCPoutput;
      TMCPoutput        = Record
                            position    : Word;
                            start       : pointer;
                            length      : Word;
                          end;

Const initStatus:BYTE=0;
      channelCount:WORD=0;
      dataBuf:WORD=0;

Var SOUNDCARD:TSoundCard;
    bufferSize:WORD;
    mcpStatus:Byte;

Type TSDI_Init          = Procedure;

Const ID_SB               = 1;
      ID_SBPRO            = 2;
      ID_PAS              = 3;
      ID_PASPLUS          = 4;
      ID_PAS16            = 5;
      ID_SB16             = 6;
      ID_DAC              = 7;
      ID_ARIA             = 8;
      ID_WSS              = 9;
      ID_GUS              = 10;

      MCP_QUALITY         = 1;
      MCP_486             = 2;
      MCP_Mono            = 4;
      MCP_TableSize       = 33*256*2+32;
      MCP_QualitySize     = 2048*2+4096+16;

      volume_Linear       = 1;
      volume_Any          = 255;

      sample_Continue     = 1;

      CH_Playing          = 1;
      CH_Looping          = 2;
      CH_Paused           = 4;
      CH_Valid            = 8;

      PAN_Left            = -63;
      PAN_Right           = 63;
      PAN_Middle          = 0;
      PAN_Surround        = 100;

Function  mcpInit(MCPstruct:PMCPstruct):Integer;
Function  mcpInitSoundDevice(sdi:TSDI_Init;SCard:PSoundCard):Integer;
Procedure mcpClose;
Procedure mcpOpenSpeaker;
Procedure mcpCloseSpeaker;
Function  mcpSetupChannels(Channels:longint;volTable:Pointer):Integer;
Function  mcpStartVoice:Integer;
Function  mcpStopVoice:Integer;
Function  mcpPauseVoice:Integer;
Function  mcpResumeVoice:Integer;
Function  mcpGetDelta:Longint;
Procedure mcpPoll(time:Longint);
Procedure mcpClearBuffer;
Function  mcpPauseChannel(Channel:longint):Integer;
Function  mcpResumeChannel(Channel:longint):Integer;
Function  mcpStopChannel(Channel:longint):Integer;
Function  mcpPauseAll:Integer;
Function  mcpResumeAll:Integer;
Function  mcpGetChannelStatus(Channel:longint):Integer;
Function  mcpGetChannelCount:Integer;
Function  mcpSetSample(Channel:longint;s:PSampleInfo):Integer;
Function  mcpPlaySample(channel:longint;rate:Longint;volume:longint):Integer;
Function  mcpSetVolume(Channel:longint;Volume:longint):Integer;
Function  mcpGetVolume(channel:longint):Word;
Function  mcpGetPosition(channel:longint):Longint;
Function  mcpGetSample(channel:longint):Pointer;
Function  mcpGetRate(channel:longint):Longint;
Function  mcpGetPanning(channel:longint):integer;
Function  mcpSetRate(Channel:longint;Rate:Longint):Integer;
Function  mcpSetPosition(Channel:longint;Position:Longint):Integer;
Procedure mcpSetPanning(channel,panning:longint);
Function  mcpSetSamplingRate(Sampling_Rate:longint):Integer;
Function  mcpGetSamplingRate:Word;
Function  mcpSetMasterVolume(Volume:longint):Integer;
Procedure mcpConvertSample(Sample:Pointer;Length:Longint);
Function  mcpGetOutput:PMCPoutput;

Procedure mcpCalibrate; interrupt;
Function  mcpCalibrateInit(delta,accuracy:longint):Integer;
Procedure mcpCalibrateClose;

Procedure nullfunction;
Procedure mcpDownload;
Procedure mcpUnloadAll;

Const CDI_MCP : TCDIdevice = (
    setsample        : @mcpSetSample;
    playsample       : @mcpPlaySample;
    setvolume        : @mcpSetVolume;
    setfrequency     : @mcpSetRate;
    setlinearrate    : @nullFunction;
    setposition      : @mcpSetPosition;
    setpanning       : @mcpSetPanning;
    setmastervolume  : @mcpSetMasterVolume;
    pausechannel     : @mcpPauseChannel;
    resumechannel    : @mcpResumeChannel;
    stopchannel      : @mcpStopChannel;
    pauseall         : @mcpPauseAll;
    resumeall        : @mcpResumeAll;
    poll             : @mcpPoll;
    getdelta         : @mcpGetDelta;
    download         : @mcpDownload;
    unload           : @mcpUnloadAll;
    getvolume        : @mcpGetVolume;
    getfrequency     : @mcpGetRate;
    getposition      : @mcpGetPosition;
    getpan           : @mcpGetPanning;
    getsample        : @mcpGetSample;
    setupch          : @mcpSetupChannels);

Implementation
{$IFDEF USE_EMS}
uses mcpems;
{$ELSE}
uses mcpreala;
{$ENDIF}

{$L MCPlayer.OBJ}
{$L CONVSAMP.OBJ}

Function  mcpInit(MCPstruct:PMCPstruct):Integer; external;
Function  mcpInitSoundDevice(sdi:TSDI_Init;SCard:PSoundCard):Integer; external;
Procedure mcpClose; external;
Procedure mcpOpenSpeaker; external;
Procedure mcpCloseSpeaker; external;
Function  mcpSetupChannels(Channels:longint;volTable:Pointer):Integer; external;
Function  mcpStartVoice:Integer; external;
Function  mcpStopVoice:Integer; external;
Function  mcpPauseVoice:Integer; external;
Function  mcpResumeVoice:Integer; external;
Function  mcpGetDelta:Longint; external;
Procedure mcpPoll(time:Longint); external;
Procedure mcpClearBuffer; external;
Function  mcpPauseChannel(Channel:longint):Integer; external;
Function  mcpResumeChannel(Channel:longint):Integer; external;
Function  mcpStopChannel(Channel:longint):Integer; external;
Function  mcpPauseAll:Integer; external;
Function  mcpResumeAll:Integer; external;
Function  mcpGetChannelStatus(Channel:longint):Integer; external;
Function  mcpGetChannelCount:Integer; external;
Function  mcpSetSample(Channel:longint;s:PSampleInfo):Integer; external;
Function  mcpPlaySample(channel:longint;rate:Longint;volume:longint):Integer; external;
Function  mcpSetVolume(Channel:longint;Volume:longint):Integer; external;
Function  mcpGetVolume(channel:longint):Word; external;
Function  mcpGetPosition(channel:longint):Longint; external;
Function  mcpGetSample(channel:longint):Pointer; external;
Function  mcpGetRate(channel:longint):Longint; external;
Function  mcpGetPanning(channel:longint):integer; external;
Function  mcpSetRate(Channel:longint;Rate:Longint):Integer; external;
Function  mcpSetPosition(Channel:longint;Position:Longint):Integer; external;
Procedure mcpSetPanning(channel,panning:longint); external;
Function  mcpSetSamplingRate(Sampling_Rate:longint):Integer; external;
Function  mcpGetSamplingRate:Word; external;
Function  mcpSetMasterVolume(Volume:longint):Integer; external;
Procedure mcpConvertSample(Sample:Pointer;Length:Longint); external;
Function  mcpGetOutput:PMCPoutput; external;

Procedure mcpCalibrate; external;
Function  mcpCalibrateInit(delta,accuracy:longint):Integer; external;
Procedure mcpCalibrateClose; external;

Procedure nullfunction; external;
Procedure mcpDownload; external;
Procedure mcpUnloadAll; external;

end.
