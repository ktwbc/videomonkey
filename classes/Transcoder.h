//
//  Transcoder.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import <Foundation/NSString.h>

#import <unistd.h>

#define LOG_FILE_PATH @"~/Library/Application Support/VideoMonkey/Logs"

@class AppController;
@class Command;
@class Metadata;
@class FileInfoPanelController;

// FrameSize is a 32 bit integer with upper 16 bits width and lower 16 bits height
typedef uint32_t FrameSize;

    //
    //  FS_INVALID      - File is invalid, we can't encode this file
    //  FS_VALID        - File is waiting to be encoded
    //  FS_ENCODING     - File is in the process of being encoded
    //  FS_PAUSED       - File is being encoded but is currently paused
    //  FS_FAILED       - An attempt was made to encode the file, but it failed
    //  FS_SUCCEEDED    - File was successfully encoded
    //
typedef enum FileStatus {   FS_INVALID,     // File is invalid, we can't encode this file
                            FS_VALID,       // File is waiting to be encoded
                            FS_ENCODING,    // File is in the process of being encoded
                            FS_PAUSED,      // File is being encoded but is currently paused
                            FS_FAILED,      // An attempt was made to encode the file, but it failed
                            FS_SUCCEEDED    // File was successfully encoded
                        } FileStatus;

@interface TranscoderFileInfo : NSObject {
    // General
    NSString* filename;
    NSString* format;
    double duration;
    double bitrate;
    double fileSize;
    
    // Video
    int videoIndex;
    NSString* videoLanguage;
    NSString* videoCodec;
    NSString* videoProfile;
    BOOL videoInterlaced;
    FrameSize videoFrameSize;
    double videoBitrate;
    double videoAspectRatio;
    double videoFrameRate;
    
    // Audio
    int audioIndex;
    NSString* audioLanguage;
    NSString* audioCodec;
    double audioSampleRate;
    int audioChannels;
    double audioBitrate;
}

// General
@property(retain) NSString* filename;
@property(retain) NSString* format;
@property(assign) double duration;
@property(assign) double bitrate;
@property(assign) double fileSize;

// Video
@property(assign) int videoIndex;
@property(retain) NSString* videoLanguage;
@property(retain) NSString* videoCodec;
@property(retain) NSString* videoProfile;
@property(assign) BOOL videoInterlaced;
@property(assign) FrameSize videoFrameSize;
@property(assign) double videoAspectRatio;
@property(assign) double videoFrameRate;
@property(assign) double videoBitrate;

// Audio
@property(assign) int audioIndex;
@property(retain) NSString* audioLanguage;
@property(retain) NSString* audioCodec;
@property(assign) double audioSampleRate;
@property(assign) int audioChannels;
@property(assign) double audioBitrate;

@end

@interface Transcoder : NSObject {
  @private
    NSMutableArray* m_inputFiles;
    TranscoderFileInfo* m_outputFileInfo;
    Metadata* m_metadata;
    double m_progress;
    BOOL m_enabled;
    FileStatus m_fileStatus;
    
    NSTask* m_task;
    NSPipe* m_pipe;
    NSMutableArray* m_commands;
    int m_currentCommandIndex;
    NSProgressIndicator* m_progressIndicator;
    NSImageView* m_statusImageView;
    BOOL m_wroteMetadata;
    
    NSFileHandle* m_logFile;
    NSString* m_tempAudioFileName;
    NSString* m_passLogFileName;
    NSString* m_audioQuality;
    float m_avOffset; // How much video is ahead of audio, in seconds (negative numbers mean audio is ahead of video)
    
}

@property (readwrite) float avOffset;
@property (readwrite) BOOL enabled;
@property (readonly) double progress;
@property (readonly) FileStatus fileStatus;
@property (readonly) NSString* audioQuality;

@property (readonly) TranscoderFileInfo* inputFileInfo;
@property (readonly) TranscoderFileInfo* outputFileInfo;
@property (retain) Metadata* metadata;
@property (readonly) FileInfoPanelController* fileInfoPanelController;

- (Transcoder*)initWithFilename:(NSString*) filename;

- (int)addInputFile: (NSString*) filename;

-(NSValue*) progressCell;

-(double) progress;
-(void) resetStatus;
-(NSProgressIndicator*) progressIndicator;
-(NSImageView*) statusImageView;

-(BOOL) hasInputAudio;
-(NSString*) tempAudioFileName;
-(NSString*) passLogFileName;

-(void) setParams;

-(BOOL) startEncode;
-(BOOL) pauseEncode;
-(BOOL) resumeEncode;
-(BOOL) stopEncode;

-(BOOL) addToMediaLibrary:(NSString*) filename;
-(void) createMetadata;

-(void) setProgressForCommand: (Command*) command to: (double) value;
-(void) commandFinished: (Command*) command status: (int) status;

-(void) updateFileInfo;
-(void) logToFile: (NSString*) string;
-(void) logCommand: (int) index withFormat: (NSString*) format, ...;
-(void) log: (NSString*) format, ...;

@end
