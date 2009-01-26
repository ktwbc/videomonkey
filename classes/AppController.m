//
//  AppController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "AppController.h"
#import "DeviceController.h"
#import "FileListController.h"
#import "JavaScriptContext.h"
#import "MoviePanelController.h"
#import "Transcoder.h"

@implementation AppController

@synthesize fileList = m_fileList;
@synthesize deviceController = m_deviceController;

static NSString* getOutputFileName(NSString* inputFileName, NSString* savePath, NSString* suffix)
{
    // extract filename
    NSString* lastComponent = [inputFileName lastPathComponent];
    NSString* inputPath = [inputFileName stringByDeletingLastPathComponent];
    NSString* baseName = [lastComponent stringByDeletingPathExtension];

    if (!savePath)
        savePath = inputPath;
        
    // now make sure the file doesn't exist
    NSString* filename;
    for (int i = 0; i < 10000; ++i) {
        if (i == 0)
            filename = [[savePath stringByAppendingPathComponent: baseName] stringByAppendingPathExtension: suffix];
        else
            filename = [[savePath stringByAppendingPathComponent: 
                        [NSString stringWithFormat: @"%@_%d", baseName, i]] stringByAppendingPathExtension: suffix];
            
        if (![[NSFileManager defaultManager] fileExistsAtPath: filename])
            break;
    }
    
    return filename;
}

- (id)init
{
    self = [super init];
    m_fileList = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    [m_fileList release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [m_totalProgressBar setUsesThreadedAnimation:YES];

    [m_stopEncodeItem setEnabled: NO];
    [m_pauseEncodeItem setEnabled: NO];
    
    [m_deviceController setDelegate:self];
    
    [self setRunState: RS_STOPPED];
}

-(Transcoder*) transcoderForFileName:(NSString*) fileName
{
    Transcoder* transcoder = [[Transcoder alloc] initWithController:self];
    [transcoder addInputFile: fileName];
    [transcoder addOutputFile: getOutputFileName(fileName, m_savePath, [m_deviceController fileSuffix])];
    [transcoder setVideoFormat: [m_deviceController videoFormat]];
    [transcoder setBitrate: [m_deviceController bitrate]];
    
    [m_moviePanel setMovie: fileName];
    
    return transcoder;
}

-(void) setOutputFileName
{
    NSEnumerator* e = [m_fileList objectEnumerator];
    Transcoder* transcoder;
    NSString* suffix = [m_deviceController fileSuffix];
    NSString* format = [m_deviceController videoFormat];
    
    while ((transcoder = (Transcoder*) [e nextObject])) {
        [transcoder changeOutputFileName: getOutputFileName([transcoder inputFileName], m_savePath, suffix)];
        [transcoder setVideoFormat: format];
    }
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [theItem isEnabled];
}

-(void) startNextEncode
{
    if (!m_isTerminated) {
        if (++m_currentEncoding < [m_fileList count]) {
            [[m_fileList objectAtIndex: m_currentEncoding] startEncode];
            return;
        }
    }
    else {
        [m_totalProgressBar setDoubleValue: 0];
        [m_fileListController reloadData];
    }
    
    [self setRunState: RS_STOPPED];
}

- (IBAction)startEncode:(id)sender
{
    [m_totalProgressBar setDoubleValue: 0];
    m_isTerminated = NO;
    
    if (m_runState == RS_PAUSED) {
        [[m_fileList objectAtIndex: m_currentEncoding] resumeEncode];
        [self setRunState: RS_RUNNING];
    }
    else {
        [self setOutputFileName];
        [self setRunState: RS_RUNNING];
    
        m_currentEncoding = -1;
        [self startNextEncode];
    }
}

- (IBAction)pauseEncode:(id)sender
{
    [[m_fileList objectAtIndex: m_currentEncoding] pauseEncode];
    [self setRunState: RS_PAUSED];
    [m_fileListController reloadData];
}

- (IBAction)stopEncode:(id)sender
{
    m_isTerminated = YES;
    [[m_fileList objectAtIndex: m_currentEncoding] stopEncode];
    [self setRunState: RS_STOPPED];
    [m_fileListController reloadData];
}

-(IBAction)toggleConsoleDrawer:(id)sender
{
    [m_consoleDrawer toggle:sender];
}

-(IBAction)changeSaveToText:(id)sender
{
    [m_savePath release];
    m_savePath = [m_saveToPathTextField stringValue];
    [m_savePath retain];
    [m_saveToPathTextField abortEditing];
    [m_saveToPathTextField setStringValue:m_savePath];
    [self setOutputFileName];
}

-(IBAction)selectSaveToPath:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Choose a Folder"];
    [panel setPrompt:@"Choose"];
    if ([panel runModalForTypes: nil] == NSOKButton) {
        m_savePath = [[panel filenames] objectAtIndex:0];
        [m_savePath retain];
        [m_saveToPathTextField setStringValue:m_savePath];
        [self setOutputFileName];
    }
}

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    [m_totalProgressBar setDoubleValue: progress];
    [m_fileListController reloadData];
}

-(void) encodeFinished: (Transcoder*) transcoder
{
    [m_totalProgressBar setDoubleValue: m_isTerminated ? 0 : 1];
    [m_fileListController reloadData];
    [self startNextEncode];
}

-(void) setRunState: (RunStateType) state
{
    if (state != RS_CURRENT)
        m_runState = state;
    
    if ([m_fileList count] == 0) {
        [m_startEncodeItem setEnabled: NO];
        [m_startEncodeItem setLabel:@"Start"];
        [m_stopEncodeItem setEnabled: NO];
        [m_pauseEncodeItem setEnabled: NO];
        return;
    }
    
    switch(m_runState) {
        case RS_STOPPED:
            [m_startEncodeItem setEnabled: YES];
            [m_startEncodeItem setLabel:@"Start"];
            [m_stopEncodeItem setEnabled: NO];
            [m_pauseEncodeItem setEnabled: NO];
            break;
        case RS_RUNNING:
            [m_startEncodeItem setEnabled: NO];
            [m_startEncodeItem setLabel:@"Start"];
            [m_stopEncodeItem setEnabled: YES];
            [m_pauseEncodeItem setEnabled: YES];
            break;
        case RS_PAUSED:
            [m_startEncodeItem setEnabled: YES];
            [m_startEncodeItem setLabel:@"Resume"];
            [m_stopEncodeItem setEnabled: YES];
            [m_pauseEncodeItem setEnabled: NO];
            break;
    }
}

-(DeviceController*) deviceController
{
    return m_deviceController;
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    
    // Output to stderr
    fprintf(stderr, [s UTF8String]);
    
    // Output to log file
    if ([m_fileList count] > m_currentEncoding)
        [(Transcoder*) [m_fileList objectAtIndex: m_currentEncoding] logToFile: s];
        
    // Output to consoleView
    [[[m_consoleView textStorage] mutableString] appendString: s];
    
    // scroll to the end
    NSRange range = NSMakeRange ([[m_consoleView string] length], 0);
    [m_consoleView scrollRangeToVisible: range];    
}

-(void) uiChanged
{
    double bitrate = [m_deviceController bitrate];
    for (Transcoder* transcoder in m_fileList)
        [transcoder setBitrate: bitrate];
    [m_fileListController reloadData];
}

@end
