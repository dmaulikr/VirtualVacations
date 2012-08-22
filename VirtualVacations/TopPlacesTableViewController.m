//
//  TopPlacesTableViewController.m
//  FlickrFetcher
//
//  Created by Norimasa Nabeta on 2012/07/27.
//  Copyright (c) 2012年 Norimasa Nabeta. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "DetailPlacesTableViewController.h"
#import "PlaceMapViewController.h"
#import "FlickrPlaceAnnotation.h"
#import "FlickrPhotoViewController.h"

#import "PlaceTableViewController.h"
#import "Photo+Flickr.h"
#import "Place.h"

@interface TopPlacesTableViewController ()
@property (nonatomic,strong) NSMutableDictionary *nations;
@end

@implementation TopPlacesTableViewController
@synthesize topPlaces=_topPlaces;
@synthesize nations=_nations;

// @synthesize photoDatabase=_photoDatabase;

- (NSArray*) topPlaces
{
    if(! _topPlaces){
        _topPlaces = [[NSArray alloc] init];
    }
    return _topPlaces;
}
-(void) setTopPlaces:(NSArray *)topPlaces
{
    if(_topPlaces != topPlaces){
        _topPlaces = topPlaces;
        if (self.tableView.window) [self.tableView reloadData];
    }
}

/*
// 4. Stub this out (we didn't implement it at first)
// 13. Create an NSFetchRequest to get all Photographers and hook it up to our table via an NSFetchedResultsController
// (we inherited the code to integrate with NSFRC from CoreDataTableViewController)

- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Place"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    // no predicate because we want ALL the Photographers

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.photoDatabase.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                            cacheName:nil];
    
}


// 5. Create a Q to fetch Flickr photo information to seed the database
// 6. Take a timeout from this and go create the database model (Photomania.xcdatamodeld)
// 7. Create custom subclasses for Photo and Photographer
// 8. Create a category on Photo (Photo+Flickr) to add a "factory" method to create a Photo
// (go to Photo+Flickr for next step)
// 12. Use the Photo+Flickr category method to add Photos to the database (table will auto update due to NSFRC)

- (void)fetchFlickrDataIntoDocument:(UIManagedDocument *)document
{
    dispatch_queue_t fetchQ = dispatch_queue_create("Flickr fetcher", NULL);
    dispatch_async(fetchQ, ^{
        NSArray *photos = [FlickrFetcher recentGeoreferencedPhotos];
        [document.managedObjectContext performBlock:^{ // perform in the NSMOC's safe thread (main thread)
            for (NSDictionary *flickrInfo in photos) {
                [Photo photoWithFlickrInfo:flickrInfo inManagedObjectContext:document.managedObjectContext];
                // table will automatically update due to NSFetchedResultsController's observing of the NSMOC
            }
            // should probably saveToURL:forSaveOperation:(UIDocumentSaveForOverwriting)completionHandler: here!
            // we could decide to rely on UIManagedDocument's autosaving, but explicit saving would be better
            // because if we quit the app before autosave happens, then it'll come up blank next time we run
            // this is what it would look like (ADDED AFTER LECTURE) ...
            [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:NULL];
            // note that we don't do anything in the completion handler this time
        }];
    });
    dispatch_release(fetchQ);
}

// 3. Open or create the document here and call setupFetchedResultsController
- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.photoDatabase.fileURL path]]) {
        // does not exist on disk, so create it
        [self.photoDatabase saveToURL:self.photoDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
            [self fetchFlickrDataIntoDocument:self.photoDatabase];
            
        }];
    } else if (self.photoDatabase.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.photoDatabase openWithCompletionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
        }];
    } else if (self.photoDatabase.documentState == UIDocumentStateNormal) {
        // already open and ready to use
        [self setupFetchedResultsController];
    }
}

// 2. Make the photoDatabase's setter start using it
- (void)setPhotoDatabase:(UIManagedDocument *)photoDatabase
{
    if (_photoDatabase != photoDatabase) {
        _photoDatabase = photoDatabase;
        [self useDocument];
    }
}
*/

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)refresh:(id)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *topPlaces = [FlickrFetcher topPlaces];
        NSLog(@"Download cont: %d", [topPlaces count]);
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:FLICKR_PLACE_NAME ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedTopPlaces = [topPlaces sortedArrayUsingDescriptors:sortDescriptors];

        NSMutableDictionary *nationDict = [[NSMutableDictionary alloc] init];
        for (NSDictionary* place in topPlaces) {
            NSString* nationTag = [FlickrFetcher nationPlace:place];
            NSMutableArray *tmp = [nationDict objectForKey:nationTag];
            if (tmp == nil) {
                tmp = [[NSMutableArray alloc] initWithObjects:place, nil];
            } else {
                [tmp addObject:place];
            }
            [nationDict setObject:tmp forKey:nationTag];
        }
        for (NSString *section in [nationDict allKeys]){
            NSArray *unsortedArray = [nationDict objectForKey:section];
            NSArray *sortedArray = [unsortedArray sortedArrayUsingDescriptors:sortDescriptors];
            [nationDict setObject:sortedArray forKey:section];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //self.navigationItem.rightBarButtonItem = sender;
            self.navigationItem.leftBarButtonItem = sender;
            self.topPlaces = sortedTopPlaces;
            self.nations = nationDict;
            [self.tableView reloadData];
        });
    });
    dispatch_release(downloadQueue);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recents = [defaults arrayForKey:FAVORITES_KEY];
    if (! recents){
        recents = [NSMutableArray array];
    }
    UITabBarItem *barItem = [[self.tabBarController.viewControllers objectAtIndex:1] tabBarItem];
    barItem.badgeValue = [NSString stringWithFormat:@"%d", [recents count]];
}

/*
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.photoDatabase) {  // for demo purposes, we'll create a default database if none is set
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Default Photo Database"];
        // url is now "<Documents Directory>/Default Photo Database"
        self.photoDatabase = [[UIManagedDocument alloc] initWithFileURL:url]; // setter will create this for us on disk
    }
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.nations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Top Places Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSArray *sortedArray = [[self.nations allKeys] sortedArrayUsingComparator:^(NSString* a, NSString* b) {
       return [a compare:b options:NSNumericSearch];
    }];
    NSString *title = [sortedArray objectAtIndex:indexPath.row];
    cell.textLabel.text = title;
    
    return cell;
}


#pragma mark - Table view delegate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Place List View"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSLog(@"Detail:indexPath %@", indexPath);

        
        NSArray *sortedArray = [[self.nations allKeys] sortedArrayUsingComparator:^(NSString* a, NSString* b) {
            return [a compare:b options:NSNumericSearch];
        }];
        NSString *title = [sortedArray objectAtIndex:indexPath.row];
        NSArray *places = [self.nations objectForKey:title];
        [segue.destinationViewController setPlaces:places ];
    }
}

@end
