// Fast native pasteboard write via Cocoa (NSPasteboard), avoiding the slow
// AppleScript "read file as «class PNGf»" coercion which can take seconds
// for larger screenshots.
//
// ARCHIVED — superseded by ClipboardWriter.swift in the native app.
function run(argv) {
  ObjC.import('Cocoa');

  var filePath = argv[0];
  var mode = argv[1]; // "image" or "file"
  var markerPath = argv[2];

  var url = $.NSURL.fileURLWithPath(filePath);
  var pbItem;
  if (mode === "image") {
    pbItem = $.NSImage.alloc.initWithContentsOfURL(url);
    if (!pbItem) return; // failed to load, bail quietly
  } else {
    pbItem = url;
  }

  // Re-check the marker AFTER loading (the slow part), right before
  // committing to the pasteboard, so a slower older copy can never
  // clobber a faster newer one.
  var markerStr = $.NSString.stringWithContentsOfFileEncodingError(markerPath, $.NSUTF8StringEncoding, null);
  var marker = markerStr ? ObjC.unwrap(markerStr) : "";
  if (marker !== filePath) return;

  var pb = $.NSPasteboard.generalPasteboard;
  pb.clearContents; // JXA auto-invokes bare no-arg ObjC selectors
  pb.writeObjects($.NSArray.arrayWithObject(pbItem));
}
