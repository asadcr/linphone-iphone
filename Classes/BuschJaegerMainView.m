/* BuschJaegerMainView.m
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "BuschJaegerMainView.h"

@implementation BuschJaegerMainView

@synthesize navigationController;
@synthesize callView;
@synthesize settingsView;
@synthesize welcomeView;
@synthesize historyView;

static BuschJaegerMainView* mainViewInstance=nil;


#pragma mark - Lifecycle Functions

- (void)initBuschJaegerMainView {
    assert (!mainViewInstance);
    mainViewInstance = self;
}

- (id)init {
    self = [super init];
    if (self) {
		[self initBuschJaegerMainView];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[self initBuschJaegerMainView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initBuschJaegerMainView];
	}
    return self;
}

- (void)dealloc {
    [navigationController release];
    [callView release];
    [settingsView release];
    [welcomeView release];
    [historyView release];
    
    // Remove all observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = navigationController.view;
    [view setFrame:[self.view bounds]];
    [self.view addSubview:view];
    [navigationController setViewControllers:[NSArray arrayWithObject:welcomeView]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdateEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
}

- (void)vieWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];
}


#pragma mark - Event Functions

- (void)callUpdateEvent: (NSNotification*) notif {
    LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    [self callUpdate:call state:state animated:TRUE];
}


#pragma mark -

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated {
    // Fake call update
    if(call == NULL) {
        return;
    }
    
    switch (state) {
		case LinphoneCallIncomingReceived:
        {
            [self displayIncomingCall:call];
        }
        case LinphoneCallOutgoingInit:
        {
            linphone_call_enable_camera(call, FALSE);
        }
        case LinphoneCallPausedByRemote:
		case LinphoneCallConnected:
        case LinphoneCallUpdated:
        {
            [navigationController popToViewController:welcomeView animated:FALSE];
            [navigationController pushViewController:callView animated:FALSE]; // No animation... Come back when Apple have learned how to create a good framework
            break;
        }
        case LinphoneCallError:
		case LinphoneCallEnd:
        {
            if ((linphone_core_get_calls([LinphoneManager getLc]) == NULL)) {
                [navigationController popToViewController:welcomeView animated:FALSE]; // No animation... Come back when Apple have learned how to create a good framework
            }
			break;
        }
        default:
            break;
	}
}

- (void)displayIncomingCall:(LinphoneCall *)call {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
        && [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
        // Create a new notification
        UILocalNotification* notif = [[[UILocalNotification alloc] init] autorelease];
        if (notif)
        {
            notif.repeatInterval = 0;
            notif.alertBody = NSLocalizedString(@"Ding Dong !",nil);
            notif.alertAction = @"See the answer";
            notif.soundName = @"01.wav";
            NSData *callData = [NSData dataWithBytes:&call length:sizeof(call)];
            notif.userInfo = [NSDictionary dictionaryWithObject:callData forKey:@"call"];
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
        }
    }else{
        [[LinphoneManager instance] enableSpeaker:TRUE];
        AudioServicesPlaySystemSound([LinphoneManager instance].sounds.call);
    }
}

+ (BuschJaegerMainView *) instance {
    return mainViewInstance;
}


@end
