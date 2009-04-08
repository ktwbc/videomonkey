//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FileInfoPanelController : NSObject {
@private
    IBOutlet NSTabView* m_fileInfoTabView;
    IBOutlet NSSearchField* m_searchField;
    IBOutlet IKImageBrowserView* m_imageBrowser;
    IBOutlet NSTableView* m_imageTable;
    IBOutlet NSButton* m_artworkDrawerDisclosureButton;

    BOOL m_isVisible;
}

-(IBAction) droppedInImage:(id)sender;

@end
