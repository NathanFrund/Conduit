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
TConduitRenderer >> renderPage: aPageName [
	| viewData pageTemplate layoutTemplate renderedPage partials |
	
	"1. Prepare the data for the templates"
	viewData := Dictionary new 
		at: 'title' put: aPageName capitalized;
		at: 'time' put: Time now print24;
		yourself.

	"2. Fetch templates (Checks Disk first, then Frozen Methods)"
	pageTemplate := self templateNamed: aPageName.
	layoutTemplate := self templateNamed: 'layout'.

	"3. Resolve all partials (for {{> navbar}} etc.)"
	partials := self resolvePartials.

	"4. Execute the render"
	^ pageTemplate 
		ifNotNil: [ 
			renderedPage := pageTemplate value: viewData partials: partials.
			
			"Wrap in layout if it exists, otherwise return raw page"
			layoutTemplate 
				ifNotNil: [ 
					viewData at: 'content' put: renderedPage.
					layoutTemplate value: viewData partials: partials ]
				ifNil: [ renderedPage ] 
		]
		ifNil: [ '<h1>404: Template not found</h1>' ]
]

{ #category : 'template-resolution' }
TConduitRenderer >> resolvePartials [
	| dict |
	"If Disk is active, use its registry" 
	(self conduit notNil and: [ self conduit registry notEmpty ]) 
		ifTrue: [ ^ self conduit registry ]. 

	"Otherwise, rebuild from Frozen methods" 
	dict := Dictionary new. 
	(self class selectors select: [ :s | s beginsWith: 'frozenTemplate' ]) do: [ :sel | 
		| key |
		key := (sel copyFrom: 15 to: sel size) asLowercase.
		dict at: key put: (MustacheTemplate on: (self perform: sel)) ]. 
	^ dict 
]

{ #category : 'accessing' }
TConduitRenderer >> templateNamed: aName [
    | methodName |
    methodName := ('frozenTemplate' , aName capitalized) asSymbol.

    "1. Check Disk (Via the conduit method, not a variable)"
    (self conduit notNil and: [ self conduit registry includesKey: aName ])
        ifTrue: [ ^ self conduit registry at: aName ].

    "2. Check Image (Frozen Methods)"
    (self respondsTo: methodName)
        ifTrue: [ ^ MustacheTemplate on: (self perform: methodName) ].

    ^ nil
]
