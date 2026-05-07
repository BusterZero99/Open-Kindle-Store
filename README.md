# Open Kindle Store v1.0

An Open Kindle Store for the Kindle Touch (KT) to get books on your Kindle
Since Amazon is shutting down their support for older devices, here is a new place to go and get your books easily
This requires your kindle to be jailbroken, and to have KUAL installed.
Based on the OPDS catalog system


## Features

- **Multiple Catalog Support**: Browse books from various OPDS catalogs including Project Gutenberg, Standard Ebooks, Feedbooks, ManyBooks, Internet Archive, and Gallica
- **Search Functionality**: Search within catalogs for specific books
- **Download Queue**: Queue multiple books for download and manage them
- **Caching**: Intelligent caching of catalog data for faster browsing
- **Settings Management**: Configure download directory and other preferences

## Installation

1. Copy the entire `Open_Kindle_Store` folder to `/mnt/us/extensions/`
2. The app will appear in the KUAL

## Usage

### Main Menu
- **Browse Catalogs**: Select from available OPDS catalogs
- **Search Books**: Search for books across catalogs
- **Download Queue**: View and manage queued downloads
- **Settings**: Configure app preferences

### Browsing Catalogs
1. Select "Browse Catalogs" from the main menu
2. Choose a catalog (Project Gutenberg, Standard Ebooks, etc.)
3. Browse the list of available books
4. Tap a book to add it to your download queue

### Download Queue
1. Select "Download Queue" from the main menu
2. View queued books
3. Tap a book to download it immediately
4. Use "Download All" to download everything in queue
5. Use "Clear Queue" to remove all items

### Settings
- **Download Directory**: Change where books are saved (edit settings.txt manually)
- **Clear Cache**: Remove cached catalog data
- **Reset to Defaults**: Restore default catalogs and settings

## Configuration Files

- `catalogs.txt`: List of available OPDS catalogs (name|url format)
- `queue.txt`: Download queue (title|author|url format)
- `settings.txt`: Application settings
- `cache/`: Cached catalog data for faster browsing

## Supported Catalogs

The app comes pre-configured with these OPDS catalogs:

1. **Project Gutenberg**: Classic public domain books
2. **Standard Ebooks**: High-quality public domain ebooks
3. **Feedbooks Public Domain**: Free public domain books
4. **ManyBooks**: Free ebooks in multiple formats

## Adding Custom Catalogs

Edit `catalogs.txt` to add more OPDS catalogs:

```
Your Catalog Name|https://example.com/opds/catalog.xml
```

## Technical Details

- Uses OPDS (Open Publication Distribution System) protocol
- Supports Atom XML feeds
- Intelligent caching (1-hour expiration)
- Touch-based navigation optimized for Kindle
- Error handling for network issues

## Troubleshooting

- **Can't load catalogs**: Check network connection
- **No books found**: Catalog may be temporarily unavailable
- **Download fails**: Check available storage space
- **App not appearing**: Ensure files are in correct location and restart Kindle

## Limitations

- Simplified UI using Kindle's e-ink display
- No advanced features like facets, borrowing, or streaming

## TODO

- Make it look like the original Kindle Store UI
- Make it be better?
