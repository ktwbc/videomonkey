//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
@private
    IBOutlet NSTableView* m_fileListView;
    NSMutableArray* m_files;
    int m_draggedRow;
}

@end