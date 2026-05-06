#!/bin/sh

# Open Kindle Store - OPDS Catalog Browser

# Configuration
CONFIG_DIR="/mnt/us/extensions/okstore"
CATALOGS_FILE="$CONFIG_DIR/catalogs.txt"
QUEUE_FILE="$CONFIG_DIR/queue.txt"
SETTINGS_FILE="$CONFIG_DIR/settings.txt"
CACHE_DIR="$CONFIG_DIR/cache"
DOWNLOAD_DIR="/mnt/us/documents"

DEFAULT_CATALOGS="Project Gutenberg|https://m.gutenberg.org/ebooks.opds/
Standard Ebooks|https://standardebooks.org/feeds/opds/
Feedbooks Public Domain|http://www.feedbooks.com/publicdomain/catalog.opds
ManyBooks|http://manybooks.net/opds/index.php
Gallica|https://gallica.bnf.fr/opds"

# Initialize directories and files
init_store() {
    mkdir -p "$CONFIG_DIR" "$CACHE_DIR"
    [ ! -f "$CATALOGS_FILE" ] && echo "$DEFAULT_CATALOGS" > "$CATALOGS_FILE"
    [ ! -f "$QUEUE_FILE" ] && touch "$QUEUE_FILE"
    [ ! -f "$SETTINGS_FILE" ] && echo "download_dir=$DOWNLOAD_DIR" > "$SETTINGS_FILE"
}

# Screen functions
clear_screen() {
    eips -c
}

print() {
    eips 1 "$1" "$2"
}

print_center() {
    local text="$1"
    local line="$2"
    local width=50
    local padding=$(( (width - ${#text}) / 2 ))
    [ $padding -lt 0 ] && padding=0
    printf '%*s%s' $padding '' "$text" | eips 1 "$line"
}

# OPDS parsing functions
parse_opds_feed() {
    local url="$1"
    local cache_file="$CACHE_DIR/$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g').xml"

    # Check cache (valid for 1 hour)
    if [ -f "$cache_file" ]; then
        local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
        [ $cache_age -lt 3600 ] && cat "$cache_file" && return
    fi

    # Download and cache
    wget -q -O "$cache_file" "$url"
    [ -f "$cache_file" ] && cat "$cache_file"
}

extract_entries() {
    awk '
    BEGIN { RS="</entry>"; FS="\n" }
    /<entry>/ {
        title=""
        author=""
        link=""
        content=""
        for(i=1;i<=NF;i++){
            if($i ~ /<title[^>]*>/){
                gsub(/.*<title[^>]*>/,"",$i)
                gsub(/<\/title>.*/,"",$i)
                title=$i
            }
            if($i ~ /<author>/){
                for(j=i;j<=NF;j++){
                    if($j ~ /<name>/){
                        gsub(/.*<name>/,"",$j)
                        gsub(/<\/name>.*/,"",$j)
                        author=$j
                        break
                    }
                }
            }
            if($i ~ /<link.*type=".*application\/.*"/){
                if($i ~ /rel="http:\/\/opds-spec.org\/acquisition"/ || $i !~ /rel=/){
                    match($i, /href="[^"]*"/)
                    link=substr($i, RSTART+6, RLENGTH-7)
                }
            }
            if($i ~ /<content/){
                content=$i
                gsub(/.*<content[^>]*>/,"",content)
                gsub(/<\/content>.*/,"",content)
            }
        }
        if(title!="" && link!=""){
            print title "|" author "|" link "|" content
        }
    }
    ' | head -n 20
}

# Menu functions
show_main_menu() {
    clear_screen
    print_center "Open Kindle Store" 1
    print 3 "1. Browse Catalogs"
    print 5 "2. Search Books"
    print 7 "3. Download Queue"
    print 9 "4. Settings"
    print 11 "5. Exit"
    print 23 "Tap to select"
}

show_catalogs_menu() {
    clear_screen
    print_center "Select Catalog" 1
    local line=3
    local num=1
    while IFS='|' read -r name url; do
        print $line "$num. $name"
        line=$((line+2))
        num=$((num+1))
    done < "$CATALOGS_FILE"
    print $line "A. Add Catalog"
    print $((line+2)) "B. Back"
}

show_search_menu() {
    clear_screen
    print_center "Search Books" 1
    print 3 "Enter search term:"
    print 5 "(Use on-screen keyboard)"
    # Kindle doesn't have easy text input, so we'll use a simple approach
    print 23 "Tap when ready to search"
}

show_queue_menu() {
    clear_screen
    print_center "Download Queue" 1
    if [ ! -s "$QUEUE_FILE" ]; then
        print 3 "Queue is empty"
    else
        local line=3
        local num=1
        while IFS='|' read -r title author link; do
            print $line "$num. $title"
            [ "$author" != "" ] && print $((line+1)) "   by $author"
            line=$((line+3))
            num=$((num+1))
        done < "$QUEUE_FILE"
        print $line "D. Download All"
        print $((line+2)) "C. Clear Queue"
    fi
    print 23 "B. Back"
}

show_settings_menu() {
    clear_screen
    print_center "Settings" 1
    print 3 "1. Download Directory"
    print 5 "2. Clear Cache"
    print 7 "3. Reset to Defaults"
    print 23 "B. Back"
}

# Browse catalog function
browse_catalog() {
    local catalog_num="$1"
    local catalog_info=$(sed -n "${catalog_num}p" "$CATALOGS_FILE")
    local name=$(echo "$catalog_info" | cut -d'|' -f1)
    local url=$(echo "$catalog_info" | cut -d'|' -f2)

    clear_screen
    print_center "Loading $name..." 1

    local feed=$(parse_opds_feed "$url")
    if [ -z "$feed" ]; then
        clear_screen
        print 5 "Failed to load catalog"
        print 7 "Check network connection"
        sleep 3
        return
    fi

    local entries=$(echo "$feed" | extract_entries)
    if [ -z "$entries" ]; then
        clear_screen
        print 5 "No books found"
        sleep 2
        return
    fi

    clear_screen
    print_center "$name" 1
    print 3 "Select a book:"

    local line=5
    local num=1
    echo "$entries" | while IFS='|' read -r title author link content; do
        print $line "$num. $title"
        [ "$author" != "" ] && print $((line+1)) "   by $author"
        line=$((line+3))
        num=$((num+1))
        [ $line -gt 20 ] && break
    done

    print 23 "Tap to select, B. Back"

    # Wait for selection
    local event=$(lipc-wait-event -m com.lab126.touch touchEvent | head -n 1)
    local y=$(echo "$event" | sed 's/.*y=\([0-9]*\).*/\1/')

    if [ "$y" -gt 500 ]; then  # Bottom area = Back
        return
    fi

    local choice=$(( (y - 5) / 60 + 1 ))
    local selected=$(echo "$entries" | sed -n "${choice}p")
    [ -z "$selected" ] && return

    local title=$(echo "$selected" | cut -d'|' -f1)
    local author=$(echo "$selected" | cut -d'|' -f2)
    local link=$(echo "$selected" | cut -d'|' -f3)

    # Add to queue
    echo "$title|$author|$link" >> "$QUEUE_FILE"
    clear_screen
    print_center "Added to Queue" 1
    print 3 "$title"
    [ "$author" != "" ] && print 5 "by $author"
    sleep 2
}

# Download from queue
download_from_queue() {
    local queue_item="$1"
    local title=$(echo "$queue_item" | cut -d'|' -f1)
    local author=$(echo "$queue_item" | cut -d'|' -f2)
    local link=$(echo "$queue_item" | cut -d'|' -f3)

    clear_screen
    print_center "Downloading..." 1
    print 3 "$title"
    [ "$author" != "" ] && print 5 "by $author"

    local safe_title=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local filename="${safe_title}.mobi"

    wget -q -O "$DOWNLOAD_DIR/$filename" "$link"

    if [ -f "$DOWNLOAD_DIR/$filename" ] && [ -s "$DOWNLOAD_DIR/$filename" ]; then
        print 7 "Download complete!"
        print 9 "Saved to Documents"
    else
        print 7 "Download failed"
    fi
    sleep 3
}

# Main application logic
main() {
    init_store

    case "$1" in
        "browse")
            show_catalogs_menu
            local event=$(lipc-wait-event -m com.lab126.touch touchEvent | head -n 1)
            local y=$(echo "$event" | sed 's/.*y=\([0-9]*\).*/\1/')
            local choice=$(( (y - 3) / 40 + 1 ))

            if [ "$choice" -le "$(wc -l < "$CATALOGS_FILE")" ]; then
                browse_catalog "$choice"
            fi
            ;;
        "search")
            show_search_menu
            # For simplicity, search in the first catalog
            local catalog_info=$(head -n 1 "$CATALOGS_FILE")
            local name=$(echo "$catalog_info" | cut -d'|' -f1)
            local url=$(echo "$catalog_info" | cut -d'|' -f2")

            clear_screen
            print_center "Searching $name..." 1
            # In a real implementation, we'd modify the URL with search terms
            # For now, just show the catalog
            sleep 2
            browse_catalog 1
            ;;
        "queue")
            show_queue_menu
            local event=$(lipc-wait-event -m com.lab126.touch touchEvent | head -n 1)
            local y=$(echo "$event" | sed 's/.*y=\([0-9]*\).*/\1/')

            if [ "$y" -gt 500 ]; then  # Back
                return
            elif [ "$y" -gt 400 ] && [ "$y" -lt 500 ]; then  # Clear
                > "$QUEUE_FILE"
                clear_screen
                print_center "Queue Cleared" 1
                sleep 2
            elif [ -s "$QUEUE_FILE" ]; then
                local choice=$(( (y - 3) / 60 + 1 ))
                local queue_item=$(sed -n "${choice}p" "$QUEUE_FILE")
                if [ -n "$queue_item" ]; then
                    download_from_queue "$queue_item"
                    # Remove from queue
                    sed -i "${choice}d" "$QUEUE_FILE"
                fi
            fi
            ;;
        "settings")
            show_settings_menu
            local event=$(lipc-wait-event -m com.lab126.touch touchEvent | head -n 1)
            local y=$(echo "$event" | sed 's/.*y=\([0-9]*\).*/\1/')

            if [ "$y" -gt 500 ]; then  # Back
                return
            fi

            local choice=$(( (y - 3) / 40 + 1 ))
            case $choice in
                1) # Download directory
                    clear_screen
                    print_center "Download Directory" 1
                    print 3 "Current: $DOWNLOAD_DIR"
                    print 5 "Directory change not implemented"
                    print 7 "Edit $SETTINGS_FILE manually"
                    sleep 3
                    ;;
                2) # Clear cache
                    rm -rf "$CACHE_DIR"/*
                    mkdir -p "$CACHE_DIR"
                    clear_screen
                    print_center "Cache Cleared" 1
                    sleep 2
                    ;;
                3) # Reset to defaults
                    echo "$DEFAULT_CATALOGS" > "$CATALOGS_FILE"
                    > "$QUEUE_FILE"
                    rm -rf "$CACHE_DIR"/*
                    mkdir -p "$CACHE_DIR"
                    clear_screen
                    print_center "Reset to Defaults" 1
                    sleep 2
                    ;;
            esac
            ;;
        *)
            # Main menu loop
            while true; do
                show_main_menu
                local event=$(lipc-wait-event -m com.lab126.touch touchEvent | head -n 1)
                local y=$(echo "$event" | sed 's/.*y=\([0-9]*\).*/\1/')
                local choice=$(( (y - 3) / 40 + 1 ))

                case $choice in
                    1) main "browse" ;;
                    2) main "search" ;;
                    3) main "queue" ;;
                    4) main "settings" ;;
                    5) exit 0 ;;
                esac
            done
            ;;
    esac
}

# Run main function
main "$@"
