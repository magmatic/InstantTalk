/*
 * Copyright 2012 shrtlist.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GKTestViewController.h"

@interface GKTestViewController () // Class extension
@property (nonatomic, strong) GKSession *gkSession;
@end

@implementation GKTestViewController

@synthesize connected = _connected;
@synthesize remotePeerID = _otherPeerID;
@synthesize gkSession;

#pragma mark - Session setup and teardown

- (void)setupSession {
    [GKVoiceChatService defaultVoiceChatService].client = self;
    self.connected = NO;
    
    self.gkSession = [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
    gkSession.delegate = self;
    gkSession.disconnectTimeout = 4;
    gkSession.available = YES;
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", gkSession.displayName];
}

- (void)teardownSession {
    [[GKVoiceChatService defaultVoiceChatService] stopVoiceChatWithParticipantID:self.remotePeerID];
    [GKVoiceChatService defaultVoiceChatService].client = nil;
    self.connected = NO;
    self.remotePeerID = nil;
    
    gkSession.available = NO;
    gkSession.delegate = nil;
    [gkSession disconnectFromAllPeers];
}

#pragma mark - Button clicks

- (void) mute_mic_action:(id)sender {
	[GKVoiceChatService defaultVoiceChatService].microphoneMuted = ![GKVoiceChatService defaultVoiceChatService].microphoneMuted;
    [self.tableView reloadData];
}

- (void) mute_snd_action:(id)sender {
	
}

- (void) pause_action:(id)sender {
    if (gkSession.available) {
        [self teardownSession];
    } else {
        [self setupSession];
    }
    [self.tableView reloadData];
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive: YES error: nil];
    
    // Routing default audio to external speaker
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    AudioSessionSetActive(true);
    
    [self setupSession];
    
}

- (void)viewDidUnload {
    // Unregister for notifications when the view is unloaded.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    else {
        return YES;
    }
}

#pragma mark - GKSessionDelegate protocol methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {	
	switch (state)
	{
		case GKPeerStateAvailable:
			NSLog(@"didChangeState: peer %@ available", [session displayNameForPeer:peerID]);
            
            [NSThread sleepForTimeInterval:0.5];
            
			[session connectToPeer:peerID withTimeout:4];
			break;
			
		case GKPeerStateUnavailable:
			NSLog(@"didChangeState: peer %@ unavailable", [session displayNameForPeer:peerID]);
			break;
			
		case GKPeerStateConnected:
			NSLog(@"didChangeState: peer %@ connected", [session displayNameForPeer:peerID]);
            gkSession = session;
            gkSession.delegate = self;
            [gkSession setDataReceiveHandler:self withContext:nil];
            
            [[GKVoiceChatService defaultVoiceChatService] startVoiceChatWithParticipantID:peerID error:nil];
            self.remotePeerID = peerID;
            self.connected = YES;
            break;
			
		case GKPeerStateDisconnected:
			NSLog(@"didChangeState: peer %@ disconnected", [session displayNameForPeer:peerID]);
            [[GKVoiceChatService defaultVoiceChatService] stopVoiceChatWithParticipantID:peerID];
            
			break;
			
		case GKPeerStateConnecting:
			NSLog(@"didChangeState: peer %@ connecting", [session displayNameForPeer:peerID]);
			break;
	}
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	NSLog(@"didReceiveConnectionRequestFromPeer: %@", [session displayNameForPeer:peerID]);
    [session acceptConnectionFromPeer:peerID error:nil];
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
	NSLog(@"connectionWithPeerFailed: peer: %@, error: %@", [session displayNameForPeer:peerID], error);
    [session disconnectFromAllPeers];
    self.connected = NO;

	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
	NSLog(@"didFailWithError: error: %@", error);
	[session disconnectFromAllPeers];
    self.connected = NO;
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {    
     
    NSString *headerTitle = nil;
    headerTitle = section == 0 ? @"Status" : @"Settings";
	return headerTitle;
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section == 1) return 3; // mute output, mute sound, availability
    return 1;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
    if ([indexPath section] == 0) {
        // display a brief status 
        
        if (gkSession.available){
            
            NSArray *connectedPeers = [gkSession peersWithConnectionState:GKPeerStateConnected];
            NSArray *connectingPeers = [gkSession peersWithConnectionState:GKPeerStateConnecting];
            NSArray *availablePeers = [gkSession peersWithConnectionState:GKPeerStateAvailable];
            NSMutableArray *unavailablePeers = [[NSMutableArray alloc] initWithArray:[gkSession peersWithConnectionState:GKPeerStateUnavailable]];
            [unavailablePeers addObjectsFromArray:[gkSession peersWithConnectionState:GKPeerStateDisconnected]];
            
            if (connectedPeers.count > 0) {
                NSString *peerID = [connectedPeers objectAtIndex:0];
                if (peerID){
                    cell.textLabel.text =  [NSString stringWithFormat:@"Connected to %@", [gkSession displayNameForPeer:peerID]];
                }
                
            } else if (connectingPeers.count > 0) {
                NSString *peerID = [connectingPeers objectAtIndex:0];
                if (peerID){
                    cell.textLabel.text =  [NSString stringWithFormat:@"Connecting to %@", [gkSession displayNameForPeer:peerID]];
                }
            } else if (availablePeers.count > 0) {
                NSString *peerID = [availablePeers objectAtIndex:0];
                if (peerID){
                    cell.textLabel.text =  [NSString stringWithFormat:@"Found %@", [gkSession displayNameForPeer:peerID]];
                }
            } else if (unavailablePeers.count > 0) {
                NSString *peerID = [unavailablePeers objectAtIndex:0];
                if (peerID){
                    cell.textLabel.text =  [NSString stringWithFormat:@"%@ is unavailable", [gkSession displayNameForPeer:peerID]];
                }
            } else {
                cell.textLabel.text = @"Online. Waiting for peers...";
            }
        } else {
            cell.textLabel.text = @"Offline";
        }
            
        
    } else {
        // display the controls
        switch ([indexPath row]){
            case 0:
            {   // mute sound
                UISwitch *toggleSwitch = [[UISwitch alloc] init];
                cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
                toggleSwitch.on = YES;
                [toggleSwitch addTarget:self action:@selector(mute_snd_action:) forControlEvents:UIControlEventTouchUpInside];
                [cell.accessoryView addSubview:toggleSwitch];
                cell.textLabel.text = @"Speaker";
                
                break;
            }
            case 1:
            {   // mute mic
                UISwitch *toggleSwitch = [[UISwitch alloc] init];
                cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
                toggleSwitch.on = ![GKVoiceChatService defaultVoiceChatService].microphoneMuted;
                [toggleSwitch addTarget:self action:@selector(mute_mic_action:) forControlEvents:UIControlEventTouchUpInside];
                [cell.accessoryView addSubview:toggleSwitch];
                cell.textLabel.text = @"Microphone";

                break;
            }
            case 2:
            {   // availability
                UISwitch *toggleSwitch = [[UISwitch alloc] init];
                cell.accessoryView = [[UIView alloc] initWithFrame:toggleSwitch.frame];
                toggleSwitch.on = gkSession.available;
                [toggleSwitch addTarget:self action:@selector(pause_action:) forControlEvents:UIControlEventTouchUpInside];
                [cell.accessoryView addSubview:toggleSwitch];
                cell.textLabel.text = @"Availability";

                break;
            }
        }
    }
    
    return cell;
}

#pragma mark - GKVoiceChatClient methods

- (NSString *)participantID {
    return gkSession.peerID;
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService 
                sendData:(NSData *)data
         toParticipantID:(NSString *)participantID
{
    [gkSession sendData:data 
                toPeers:[NSArray arrayWithObject:participantID] 
           withDataMode:GKSendDataReliable 
                  error:nil];
}

- (void)receiveData:(NSData *)data 
           fromPeer:(NSString *)peer
          inSession:(GKSession *)session
            context:(void *)context;
{
    [[GKVoiceChatService defaultVoiceChatService] receivedData:data 
                                             fromParticipantID:peer];
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStopWithParticipantID:(NSString *)participantID 
                   error:(NSError *)error {
    self.connected = NO;
}

-  (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStartWithParticipantID:(NSString *)participantID {
    self.connected = YES;
}


@end