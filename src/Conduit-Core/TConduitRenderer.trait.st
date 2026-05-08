"
I am a Trait responsible for Context-Aware Rendering.

I provide the logic necessary to detect and respond to HTMX (HX-Request) headers, allowing a single route to serve both full-page layouts and surgical HTML fragments. My goal is to keep the application code ""DRY"" (Don't Repeat Yourself) by centralizing the rendering switch.

## 1. The Decision Switch

My primary entry point is #render:request:context:.

If it's an HTMX request: I call #renderFragment:context: to return only the specific snippet requested.

If it's a standard request: I call #renderFullPage:context: to wrap the content in the global site layout (navigation, CSS, scripts).

## 2. Key Methods

*isHtmxRequest:* - Inspects the ZnRequest headers for the HX-Request: true pair.

*renderFragment:context:* - Performs a lookup in the template registry and evaluates it against the provided data dictionary.

*resolvePartials* - [Requirement] The using class must provide this method to return the dictionary of available MustacheTemplate objects.

## 3. Why Use This Trait?

By applying me to a WebApp class, you can write routes that don't care about the delivery method. The route simply asks to ""render"" a template, and I handle the negotiation between the server and the browser's DOM.

## 4. Usage Example

""In a Teapot route""
server GET: '/profile' -> [ :req | 
    self render: 'profile_view' request: req context: { 'user' -> currentUser } asDictionary ].
"
Trait {
	#name : 'TConduitRenderer',
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'accessing' }
TConduitRenderer >> conduit [ 
	^ self subclassResponsibility 
]

{ #category : 'rendering' }
TConduitRenderer >> layoutNameForPage: aPageName [
    | pageLayout |
    pageLayout := aPageName , '_layout'.
    (self templateNamed: pageLayout) ifNotNil: [ ^ pageLayout ].
    ^ 'layout'
]

{ #category : 'rendering' }
TConduitRenderer >> renderPage: aPageName [
    ^ self renderPage: aPageName context: Dictionary new
]

{ #category : 'rendering' }
TConduitRenderer >> renderPage: aPageName context: aDictionary [
    "Render a page with a page‑specific layout if one exists, otherwise the default."
    ^ self renderPage: aPageName layout: (self layoutNameForPage: aPageName) context: aDictionary
]

{ #category : 'rendering' }
TConduitRenderer >> renderPage: aPageName layout: aLayoutName context: aDictionary [
    "Render a page with a specific layout"
    
    | pageTemplate layoutTemplate partials renderedPage |
    
    pageTemplate := self templateNamed: aPageName.
    layoutTemplate := self templateNamed: aLayoutName.
    partials := self resolvePartials.
    
    renderedPage := pageTemplate 
        ifNotNil: [ pageTemplate value: aDictionary partials: partials ]
        ifNil: [ '<h1>404: Template not found</h1>' ].
    
    layoutTemplate ifNotNil: [
        | layoutContext |
        layoutContext := aDictionary copy
            at: 'content' put: renderedPage;
            yourself.
        ^ layoutTemplate value: layoutContext partials: partials ].
    
    ^ renderedPage
]

{ #category : 'template-resolution' }
TConduitRenderer >> resolvePartials [
    | dict prefix |
    (self conduit notNil and: [ self conduit registry notEmpty ])
        ifTrue: [ ^ self conduit registry ].

    prefix := 'frozenTemplate'.
    dict := Dictionary new.
    (self class selectors select: [ :s | s beginsWith: prefix ]) do: [ :sel |
        | key |
        key := Conduit unescapeSelectorToPath: (sel copyFrom: prefix size + 1 to: sel size).
        dict at: key put: (MustacheTemplate on: (self perform: sel)) ].
    ^ dict
]

{ #category : 'accessing' }
TConduitRenderer >> templateNamed: aName [
    | methodName |
    "1. Disk check (development mode)"
    self conduit ifNotNil: [ :c |
        c syncIfNeeded.
        (c registry includesKey: aName asLowercase) ifTrue: [ ^ c registry at: aName asLowercase ] ].

    "2. Image fallback (frozen methods)"
    methodName := ('frozenTemplate' , (Conduit escapePathForSelector: aName)) asSymbol.
    (self respondsTo: methodName)
        ifTrue: [ ^ MustacheTemplate on: (self perform: methodName) ].
    ^ nil
]
