//
//  InfoViewController.m
//  InstantTalk
//
//  Copyright (c) 2014 Black Magma Inc. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()
@property (nonatomic, copy) NSArray *texts;
@property (nonatomic, copy) NSArray *headLines;
@property (nonatomic) CGFloat fontSize;

@end

@implementation InfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor viewFlipsideBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _headLines = [NSArray arrayWithObjects: @"About", @"Availability", @"Disable auto-lock", @"Darken screen", @"Microphone", nil];
    
    _texts = [NSArray arrayWithObjects:
             [NSString stringWithFormat:@"%@ provides an easy way to have voice conversations with another iOS device when traditional cell network is unreliable, undesirable or unavailable altogether. Just open the app on two devices and wait a few seconds for them to get connected. No buttons to press, just turn on and talk! While it can work over both wifi and Bluetooth, for truly autonomous peer-to-peer operation we suggest you use Bluetooth and turn wifi off. %@ will attempt to automatically re-establish any lost connections, such as when devices temporarily move out of each other's range and then come back. Note that if you experience frequent loss of connection you may be reaching the limits of your devices' Bluetooth range or are subject to interference; in such cases, experiment with device placement to improve performance.", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]],
             @"Turn off to stop current connections and prevent any further connection requests. Availability must be on to establish new connections.", 
             [NSString stringWithFormat:@"Leave on to ensure dropped connections get automatically re-established. While an ongoing conversation will continue even when the app is in the background and/or the device is in sleep mode, automatic reconnects require the device to be on, unlocked and %@ to be the active app.", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]],
             @"Turn this option on to reduce backlight and save battery power during extended talk sessions.", 
             @"Turn off to mute outgoing sound. To adjust volume of incoming audio, use hardware buttons on your device or headset.", 
             nil];
    
    _fontSize = 14.0f;
    
    [self.tableView setBackgroundView:[[UIView alloc] init]];

    self.title = @"Info";
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(action_dismiss:)];
    self.navigationItem.rightBarButtonItem = doneBtn;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) action_dismiss: (id) sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = sectionTitle;
    label.textAlignment = UITextAlignmentCenter;
    
    if (section == 0 && [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] isEqualToString:@"InstantTalk"]){
        UIImageView *mammoth = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arse48"]];
        mammoth.center = CGPointMake(tableView.frame.size.width / 4, 27);
        [label addSubview:mammoth];

    }
    
    return (UIView *) label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) return 50;
    else return 40;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{    
    return [_headLines objectAtIndex:section];
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{
    return 1; 
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger margin = 12;
    
    NSString *text = [_texts objectAtIndex:[indexPath section]];
    
    CGSize constraint = CGSizeMake(tableView.frame.size.width - (margin * 2), 20000.0f);
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:_fontSize] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height = MAX(size.height, 44.0f);
    
    return height + (margin * 2);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor darkGrayColor];
        cell.textLabel.font = [UIFont systemFontOfSize:_fontSize];
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.numberOfLines = 0;
    }
	        
    cell.textLabel.text = [_texts objectAtIndex:[indexPath section]];
	
	return cell;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

@end
