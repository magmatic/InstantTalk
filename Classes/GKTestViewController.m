/*
 //  InstantTalk
 //
 //  Copyright (c) 2014 Black Magma Inc. All rights reserved.
 */

#import "GKTestViewController.h"
#import "InfoViewController.h"
@class InfoViewController;

@interface GKTestViewController () // Class extension
@property (nonatomic, strong) GKSession *gkSession;
@property (nonatomic) BOOL manualOff; // turned on when user manually turns off availability
@property (nonatomic, retain) UILabel *darkScreen;
@property (nonatomic, retain) UIView *brightScreen;

@end

@implementation GKTestViewController

BOOL verbal = YES;

// set to true by the peer that accepted the connection
// reset to false when disconnected or re-enabling the service
BOOL accepted;

#pragma mark - Handling moving to and from background state

- (void) suspend{
    
    // if there is no active connection, close the service
    if ([self countActivePeers] < 1 && !_manualOff) {
        [self teardownSession];
        if (verbal) NSLog(@"Suspending");
    }
}
- (void) resume{
    
    // check that we are not currently connected to anyone
    // and that the user did not choose to manually go offline before suspending
    
    if ([self countActivePeers] < 1 && !_manualOff) {
        [self setupSession];
        if (verbal) NSLog(@"Resuming");
    }
}

- (NSUInteger) countActivePeers{
    return [[self.gkSession peersWithConnectionState:GKPeerStateConnected] count] + [[self.gkSession peersWithConnectionState:GKPeerStateConnecting] count];
}

#pragma mark - GKSession setup and teardown

- (void)setupSession {
    [self setAudio];
    accepted = NO;
    
    self.gkSession = [[GKSession alloc] initWithSessionID:@"instant_bt_talk" displayName:nil sessionMode:GKSessionModePeer];
    self.gkSession.delegate = self;
    [self.gkSession setDataReceiveHandler:self withContext:nil];
    self.gkSession.disconnectTimeout = 5;

    self.gkSession.available = YES;
}

- (void)teardownSession {
    accepted = NO;
    
    // stop voice chat with all peers
    self.gkSession.available = NO;
    for (NSString *peerID in [self.gkSession peersWithConnectionState:GKPeerStateConnected]) {
        [[GKVoiceChatService defaultVoiceChatService] stopVoiceChatWithParticipantID:peerID];
    }
    [GKVoiceChatService defaultVoiceChatService].client = nil;

    [self.gkSession disconnectFromAllPeers];
    self.gkSession.delegate = nil;
}

#pragma mark - Button clicks

- (void) autolock_action:(id)sender {
    UISwitch *toggle = (UISwitch *) sender;
    [[UIApplication sharedApplication] setIdleTimerDisabled:toggle.on];
}

- (void) mute_action:(id)sender {
	[GKVoiceChatService defaultVoiceChatService].microphoneMuted = ![GKVoiceChatService defaultVoiceChatService].microphoneMuted;
    [self.tableView reloadData];
}

- (void) pause_action:(id)sender {
    if (self.gkSession.available) {
        [self teardownSession];
        _manualOff = YES;
    } else {
        [self setupSession];
        _manualOff = NO;
    }
    [self.tableView reloadData];
}

- (void) dim_screen_action:(id)sender {
    self.brightness = [[UIScreen mainScreen] brightness];
    [[UIScreen mainScreen] setBrightness:0.0];
    
    _brightScreen = self.view;
    self.view = _darkScreen;
}

- (void)restore_screen_action:(id)sender {
    // helper for double taps while screen darkened
    [[UIScreen mainScreen] setBrightness:self.brightness];
    self.view = _brightScreen;
    [self.tableView reloadData];
}

- (void) info_action:(id)sender {
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[[InfoViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

- (void)setAudio{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    audioSession.delegate = self;
    [audioSession setActive: NO error: nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    [audioSession setMode: AVAudioSessionModeVoiceChat error:NULL];
    UInt32 allowMixing = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
    
    [audioSession setActive: YES error: NULL];
    
    [GKVoiceChatService defaultVoiceChatService].client = self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[UIView alloc] init]];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    _manualOff = NO;
    
    [self setAudio];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"], [[UIDevice currentDevice] name]];
    self.brightness = [[UIScreen mainScreen] brightness];
            
    // Create a custom darkened screen view that responds to double taps only 
    // to prevent accidental taps while dimmed and potentially in a pocket
    _darkScreen = [[UILabel alloc] initWithFrame:self.view.frame];
    _darkScreen.text = @"Double tap to return";
    _darkScreen.textColor = [UIColor whiteColor];
    _darkScreen.textAlignment = UITextAlignmentCenter;
    _darkScreen.backgroundColor = [UIColor blackColor];
    _darkScreen.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restore_screen_action:)];
    tapGesture.numberOfTapsRequired = 2;
    [_darkScreen addGestureRecognizer:tapGesture];
}

- (void)viewDidUnload {
    [self teardownSession];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

#pragma mark - GKSessionDelegate protocol methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{	
	switch (state)
	{
		case GKPeerStateAvailable:
			if (verbal) NSLog(@"changeState: %@ available", [session displayNameForPeer:peerID]);
            [NSThread sleepForTimeInterval:0.5];
            [session connectToPeer:peerID withTimeout:5];
			break;
						
		case GKPeerStateConnected:
			if (verbal) NSLog(@"changeState: %@ connected", [session displayNameForPeer:peerID]);
           
            [[GKVoiceChatService defaultVoiceChatService] startVoiceChatWithParticipantID:peerID error:nil];
			break;
			
		case GKPeerStateDisconnected:
			if (verbal) NSLog(@"changeState: %@ disconnected", [session displayNameForPeer:peerID]);
            if (accepted) {
                [self teardownSession];
                sleep(1);
                [self setupSession];
            }
			break;
        case GKPeerStateUnavailable:
			if (verbal) NSLog(@"changeState: %@ unavailable", [session displayNameForPeer:peerID]);
            if (accepted) {
                [self teardownSession];
                sleep(1);
                [self setupSession];
            }
            break;
	
		case GKPeerStateConnecting:
			if (verbal) NSLog(@"changeState: %@ connecting", [session displayNameForPeer:peerID]);
			break;
	}
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	if (verbal) NSLog(@"connectionRequestFromPeer: %@", [session displayNameForPeer:peerID]);
    [session acceptConnectionFromPeer:peerID error:nil];
    
    accepted = YES;
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	if (verbal) NSLog(@"connectionWithPeerFailed: peer: %@, error: %@", [session displayNameForPeer:peerID], error);
    
    if ([[session peersWithConnectionState:GKPeerStateAvailable] containsObject:peerID] && ![[session peersWithConnectionState:GKPeerStateConnecting] containsObject:peerID]){
        [NSThread sleepForTimeInterval:2.0];
        // check against a fresh list of peers in case peer requested connection from the other side
        if ([[session peersWithConnectionState:GKPeerStateAvailable] containsObject:peerID] && ![[session peersWithConnectionState:GKPeerStateConnecting] containsObject:peerID]) [session connectToPeer:peerID withTimeout:5];
    }
    
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	if (verbal) NSLog(@"didFailWithError: error: %@", error);
	
	[session disconnectFromAllPeers];
	
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{    
    return section == 0 ? @"Status" : @"Settings";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor lightGrayColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.text = sectionTitle;
    label.textAlignment = UITextAlignmentCenter;
    
    return (UIView *) label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [infoButton sizeToFit];
        infoButton.backgroundColor = [UIColor clearColor];
        [infoButton addTarget:self action:@selector(info_action:) forControlEvents:UIControlEventTouchUpInside];
        infoButton.frame = CGRectMake(100, 0, self.view.frame.size.width - 200, 40);
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, infoButton.frame.size.height)];
        [container addSubview:infoButton];
        return container;
    } else return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) return 36;
    else return 0.0;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{
    return section == 0 ? 1 : 4; // rows in second section: disable auto-lock, mute sound, availability, brightness
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.backgroundColor = [UIColor darkGrayColor];

    NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
    
    if (section == 0) {
        cell.textLabel.numberOfLines = 0;
        
        NSArray *connectedPeers = [self.gkSession peersWithConnectionState:GKPeerStateConnected];
        NSArray *connectingPeers = [self.gkSession peersWithConnectionState:GKPeerStateConnecting];
        NSArray *availablePeers = [self.gkSession peersWithConnectionState:GKPeerStateAvailable];
        NSArray *unavailablePeers = [self.gkSession peersWithConnectionState:GKPeerStateUnavailable];
        NSArray *disconnectedPeers = [self.gkSession peersWithConnectionState:GKPeerStateDisconnected];
        
        NSString *text = @"";
        
        if (self.gkSession.available){
            unsigned int peerCount = [connectedPeers count] + [connectingPeers count] + [availablePeers count] + [unavailablePeers count] + [disconnectedPeers count];
            
            if (peerCount == 0) {
                text = @"Online: waiting for connections";
            } else {
                for (NSString *peerID in connectedPeers) {
                    text = [NSString stringWithFormat:@"%@Connected: %@\n", text, [self.gkSession displayNameForPeer:peerID]];
                }
                for (NSString *peerID in connectingPeers) {
                    text = [NSString stringWithFormat:@"%@Connecting: %@\n", text, [self.gkSession displayNameForPeer:peerID]];
                }
                for (NSString *peerID in availablePeers) {
                    text = [NSString stringWithFormat:@"%@Available: %@\n", text, [self.gkSession displayNameForPeer:peerID]];
                }
                for (NSString *peerID in unavailablePeers) {
                    text = [NSString stringWithFormat:@"%@Unavailable: %@\n", text, [self.gkSession displayNameForPeer:peerID]];
                }
                for (NSString *peerID in disconnectedPeers) {
                    text = [NSString stringWithFormat:@"%@Disconnected: %@\n", text, [self.gkSession displayNameForPeer:peerID]];
                }
            }
        } else {
            text = @"Offline";
        }

        cell.textLabel.text = text;

    } else {
        UISwitch *toggleSwitch;
        if (row == 0){
            // availability
            toggleSwitch = [self makeSwitch:self.gkSession.available action:@selector(pause_action:)];
            cell.textLabel.text = @"Availability";
        } else if (row == 1) {
            // toggle autolock
            toggleSwitch = [self makeSwitch:[[UIApplication sharedApplication] isIdleTimerDisabled] action:@selector(autolock_action:)];
            cell.textLabel.text = @"Disable auto-lock";
        } else if (row == 2) {
            // dim screen
            toggleSwitch = [self makeSwitch:[UIScreen mainScreen].brightness == 0.0 action:@selector(dim_screen_action:)];
            cell.textLabel.text = @"Darken screen";
        } else {
            // mute mic
            toggleSwitch = [self makeSwitch:![GKVoiceChatService defaultVoiceChatService].microphoneMuted action:@selector(mute_action:)];
            cell.textLabel.text = @"Microphone";
        }
        cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
        [cell.accessoryView addSubview:toggleSwitch];

    }
	
	return cell;
}

- (UISwitch *) makeSwitch:(BOOL)on action:(SEL)action{
    UISwitch *toggleSwitch = [[UISwitch alloc] init];
    toggleSwitch.on = on;
    [toggleSwitch addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    toggleSwitch.onTintColor = [UIColor blackColor];
    return toggleSwitch;
}

#pragma mark - AVAudioSessionDelegate methods

- (void)beginInterruption{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive: NO error: nil];
}

- (void)endInterruption{
    [self setAudio];
}

#pragma mark - GKVoiceChatClient methods

- (NSString *)participantID {
    return self.gkSession.peerID;
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService sendData:(NSData *)data toParticipantID:(NSString *)participantID {
    [self.gkSession sendData:data toPeers:[NSArray arrayWithObject:participantID] withDataMode:GKSendDataUnreliable error:nil];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    [[GKVoiceChatService defaultVoiceChatService] receivedData:data fromParticipantID:peer];
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStopWithParticipantID:(NSString *)participantID error:(NSError *)error {
}

-  (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStartWithParticipantID:(NSString *)participantID {
}

@end