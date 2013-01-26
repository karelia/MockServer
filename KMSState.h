//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

/**
 Potentially server states.
 */

typedef NS_ENUM(NSUInteger, KMSState)
{
    /// Server hasn't been started yet.
    KMSReady,

    /// Server is running.
    KMSRunning,

    /// Server is running, something called KMSPauseRequested
    KMSPauseRequested,

    /// Server is paused.
    KMSPaused,

    /// Server is stopped.
    KMSStopped
};

