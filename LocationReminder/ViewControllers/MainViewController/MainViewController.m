//
//  MainViewController.m
//  LocationReminder
//
//  Created by Fahad Jamal on 08/09/2015.
//  Copyright (c) 2015 ifahja. All rights reserved.
//

#import "MainViewController.h"
#import "ArrayManager.h"
#import "SVProgressHUD.h"
#import "Constants.h"
#import "MyAnnotation.h"
#import "LocationManager.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *mainTableView;

@property (nonatomic, strong) IBOutlet UILabel *noReminderLabel;

@end

@implementation MainViewController

#pragma mark - Default Init Method -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self.navigationItem setTitle:@"Reminders List"];
    
    UIBarButtonItem *addLocationBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Reminder"
                                                                     style:UIBarButtonItemStylePlain target:self
                                                                     action:@selector(addLocationBarButtonTapped:)];
    [self.navigationItem setRightBarButtonItem:addLocationBarButton];
    
    if (![[ArrayManager sharedInstance] isNetworkReachable]) {
        [SVProgressHUD showErrorWithStatus:INTERNET_ERROR];
    }
    
    NSMutableArray *annotationsListArray = [[ArrayManager sharedInstance] getAllReminders];
    if ([annotationsListArray count] > 0) {
        for (NSMutableDictionary *annotationDict in annotationsListArray) {
            NSLog(@"annotationDict is %@", annotationDict);
            MyAnnotation *myAnnotation = [[MyAnnotation alloc] init];
            myAnnotation.title = [annotationDict valueForKey:@"Title"];
            myAnnotation.subtitle = [annotationDict valueForKey:@"SubTitle"];
            
            CLLocationCoordinate2D center;
            center.latitude = [[annotationDict valueForKey:@"Latitude"] doubleValue];
            center.longitude = [[annotationDict valueForKey:@"Longitude"] doubleValue];
            
            myAnnotation.coordinate = center;
            [[LocationManager sharedInstance] monitorSpecificRegion:myAnnotation];
        }
    }

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Do any additional setup after loading the view, typically from a nib.
    if ([[[ArrayManager sharedInstance] getAllReminders] count] > 0) {
        [_noReminderLabel setHidden:YES];
    }
    else {
        [_noReminderLabel setHidden:NO];
    }
    
    [_mainTableView reloadData];
}

#pragma mark - UITableViewDataSource Method -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[ArrayManager sharedInstance] getAllReminders] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the appearance of table view cells in detailviewController.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Set up the cell...
    NSMutableDictionary *dict = [[[ArrayManager sharedInstance] getAllReminders] objectAtIndex:indexPath.row];
    NSString *titleString = [NSString stringWithFormat:@"%@", [dict objectForKey:@"Title"]];
    cell.textLabel.text = titleString;
    
    NSLog(@"dict is %@", dict);
    
    return cell;
}

#pragma mark - UITableViewDelegate Method -

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - BarButtonAction Method -

-(IBAction)addLocationBarButtonTapped:(id)sender {
    [self performSegueWithIdentifier:@"MapViewController" sender:self];
}

#pragma mark - Default De-Init Method -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    _mainTableView = nil;
    _noReminderLabel = nil;
}

@end

