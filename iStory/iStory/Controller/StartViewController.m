#import "StartViewController.h"
#import "StoryViewController.h"
#import "XMLParser.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StartViewController

@synthesize stories, storyViewController, documentsDir;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Define the documents folder of this app
    documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Prepare the array for the stories that needs to be shown
    stories = [[NSMutableArray alloc] init];
    
    // Read XML formatted story files in zipped stories
    [self readZippedFiles];
    
    // Get the images for the stories which will be shown as tiles to select a story
    [self getStoryImages];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/*
 * Check all iStory zip files in the documents folder and read the XML formatted story file. After reading the story file, parse the data to save the story as Story object.
 */
- (void)readZippedFiles
{
    // Define the path to the iStory zip files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDir error:nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.iStory'"];
    NSArray *onlyIStories = [dirContents filteredArrayUsingPredicate:filter];
    
    // Loop through each iStory zip file
    for (NSString *filePath in onlyIStories) {
        // Unzip the iStory zip file
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:[documentsDir stringByAppendingPathComponent:filePath] mode:ZipFileModeUnzip];
        NSArray *infos = [unzipFile listFileInZipInfos];
        
        // Loop through each file in the iStory zip
        for (FileInZipInfo *info in infos) {
            // Check if the file ends with xml, which means it contains the story data
            if (![[info.name substringToIndex:1] isEqualToString:@"_"] &&
                ![[info.name substringFromIndex:info.name.length-1] isEqualToString:@"/"] &&
                [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"xml"]) {
                [unzipFile locateFileInZip:info.name];
                
                // Read the file data
                ZipReadStream *read = [unzipFile readCurrentFileInZip];
                NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
                int bytesRead = [read readDataWithBuffer:data];
                
                // Parse the data from the file to save if as a Story object
                if (bytesRead > 0)
                    [self parse:data zipFilename:filePath];
                
                // Close the file
                [read finishedReading];
            }
        }
        
        // Close the iStory zip file
        [unzipFile close];
    }
}

/*
 * Loop through all stories and check the corresponding iStory zip files in the documents folder for the image for the stories which will be shown as tiles to select a story
 */
- (void)getStoryImages
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Loop through all stories
    for (Story *story in stories) {
        if (story.image != nil && ![story.image isEqualToString:@""]) {
            // Unzip the iStory zip file
            ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:[documentsDir stringByAppendingPathComponent:story.zipFilename] mode:ZipFileModeUnzip];
            
            // Locate the image file
            [unzipFile locateFileInZip:story.image];
            FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];
            
            // Read the image file data
            ZipReadStream *read = [unzipFile readCurrentFileInZip];
            NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
            int bytesRead = [read readDataWithBuffer:data];
            
            // Write the image file data to a new file (create a copy of the image file)
            if (bytesRead > 0) {
                if (![fileManager fileExistsAtPath:[documentsDir stringByAppendingPathComponent:story.name] isDirectory:nil])
                    [fileManager createDirectoryAtPath:[documentsDir stringByAppendingPathComponent:story.name] withIntermediateDirectories:YES attributes:nil error:NULL];
                
                [data writeToFile:[[documentsDir stringByAppendingPathComponent:story.name] stringByAppendingPathComponent:story.image] atomically:YES];
            }
            
            // Close the file
            [read finishedReading];
            
            // Close the iStory zip file
            [unzipFile close];
        }
    }
    
}

/*
 * Parse the given data to save it as Story object
 *
 * @param data The story data
 * @param zipFilename The iStory zip filename corresponding to the story
 */
- (void)parse:(NSData *)data zipFilename:(NSString *)zipFilename
{
    // Initialize the XML Parser with the given data
    NSXMLParser *nsXmlParser = [[NSXMLParser alloc] initWithData:data];
    XMLParser *parser = [[XMLParser alloc] initXMLParser];
    [nsXmlParser setDelegate:parser];
    
    // Let the XML Parser parse the given data and save the created Story object
    BOOL success = [nsXmlParser parse];
    if (success) {
        parser.story.zipFilename = zipFilename;
        [stories addObject:parser.story];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // If there are any stories, devide by two to show two tiles side by side
    if (stories.count > 0)
        return stories.count/2+1;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.rowHeight)];
    }
    
    [cell setSelectionStyle:UITableViewCellEditingStyleNone];
    
    // Create the tiles corresponding to the stories
    if (stories.count > 0) {
        if (indexPath.row*2 < stories.count) {
            [self createTile:indexPath.row*2 forCell:cell];
        }
        if (indexPath.row*2+1 < stories.count) {
            [self createTile:indexPath.row*2+1 forCell:cell];
        }
    }
    
    return cell;
}

/*
 * Create a clickable tile containing the image for the corresponding story and add it to the given table cell
 *
 * @param index The index of the corresponding story
 * @param cell The cell which the created tile needs to be added to
 */
- (void)createTile:(NSInteger)index forCell:(UITableViewCell *)cell
{
    // Define width, height and position of the tile
    NSInteger width = 495;
    NSInteger height = 300;
    NSInteger x = index%2 == 0 ? 12 : 517;
    NSInteger y = 10;
    
    // Initialize the image corresponding to the story
    UIImage *image;
    if ([[stories objectAtIndex:index] valueForKey:@"image"] != nil && ![[[stories objectAtIndex:index] valueForKey:@"image"] isEqualToString:@""]) {
        NSString *storyDir = [documentsDir stringByAppendingPathComponent:[[stories objectAtIndex:index] name]];
        image = [UIImage imageWithContentsOfFile:[storyDir stringByAppendingPathComponent:[[stories objectAtIndex:index] valueForKey:@"image"]]];
    } else {
        image = [UIImage imageNamed:@"defaultStoryImage.png"];
    }
    
    // Initialize the view with the image corresponding to the story
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    // Center the image in the tile
    if (imageView.frame.size.width > width || imageView.frame.size.height > height) {
        if (((width/imageView.frame.size.width)*imageView.frame.size.height) <= height) {
            NSInteger imageHeight = (width/imageView.frame.size.width)*imageView.frame.size.height;
            imageView.frame = CGRectMake(x, (y+((height-imageHeight)/2)), width, imageHeight);
        } else {
            NSInteger imageWidth = (height/imageView.frame.size.height)*imageView.frame.size.width;
            imageView.frame = CGRectMake((x+((width-imageWidth)/2)), y, imageWidth, height);
        }
    } else {
        imageView.frame = CGRectMake((x+((width-imageView.frame.size.width)/2)), (y+((self.view.frame.size.height-imageView.frame.size.height)/2)), imageView.frame.size.width, imageView.frame.size.height);
    }
    
    // Add the view with the image corresponding to the story to the given table cell
    [cell addSubview:imageView];
    
    // Initialize a button for the tile so the tile is clickable
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [button setTag:index];
    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add the button to the given table cell
    [cell addSubview:button];
}

/*
 * If a tile is tabbed, the button activates this action. Start the story corresponding to the tile.
 *
 * @param sender The button corresponding to the tabbed tile
 */
- (IBAction)buttonPressed:(id)sender
{
    storyViewController = [[StoryViewController alloc] initWithStory:[stories objectAtIndex:((UIButton *)sender).tag]];
    [self.navigationController pushViewController:storyViewController animated:YES];
}

@end