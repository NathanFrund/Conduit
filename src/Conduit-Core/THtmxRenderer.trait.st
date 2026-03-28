"
I am a specialized Trait that adds HTMX capabilities to a web application.

My primary role is to act as a ""Traffic Controller"" for incoming HTTP requests. I inspect the request headers to determine if the browser is asking for a full page refresh or a surgical DOM update (a fragment).

## 1. The ""Switch"" Logic
The core of my functionality lives in #isHtmxRequest:.

HTMX Request: Triggered by an hx-get or hx-post attribute in the browser. I detect the HX-Request: true header and tell the app to render only the requested snippet.

Standard Request: Triggered by a URL bar entry or a normal link. I tell the app to wrap the snippet in a Full Page Layout (including CSS, JS, and Navigation).

## 2. Key Methods
#render:request:context: - The main entry point. It uses #isHtmxRequest: to decide which rendering path to take.

isHtmxRequest: - A boolean check against the Zinc request headers.

renderFragment:context: - Handles the lookup and evaluation of the specific Mustache template requested.

## 3. Why Use This Trait?
Without me, every route in your application would need an if/else block to check for HTMX headers. By using me, your routes remain clean: they simply call #render:request:context:, and I handle the negotiation.

## 4. Example Workflow
Browser clicks <button hx-get=""/clicked"">.

Teapot routes to the /clicked block.

WebApp calls self render: 'response' request: req ....

I (the Trait) see the HTMX header and return only the HTML for 'response'.
"
Trait {
	#name : 'THtmxRenderer',
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'testing' }
THtmxRenderer >> isHtmxRequest: aRequest [
    | isHtmx |
    aRequest ifNil: [ ^ false ].

    isHtmx := (aRequest headers at: 'HX-Request' ifAbsent: [ 'false' ]) = 'true'.

    "Change pathString to asString"
    Transcript 
        show: '[HTMX Check] Path: ', aRequest url asString;
        show: ' | Is HTMX? ', isHtmx asString; 
        cr.

    ^ isHtmx
]

{ #category : 'rendering' }
THtmxRenderer >> render: aTemplateName request: aRequest context: aDictionary [
    "The Decision Maker"
    ^ (self isHtmxRequest: aRequest)
        ifTrue: [ self renderFragment: aTemplateName context: aDictionary ]
        ifFalse: [ self renderPage: aTemplateName context: aDictionary ]
]

{ #category : 'rendering' }
THtmxRenderer >> renderFragment: aTemplateName context: aDictionary [
    | templateRegistry targetTemplate |
    
    "1. Get the dictionary (Registry) of all templates"
    templateRegistry := self resolvePartials.
    
    "2. Look up the specific template by name"
    "We use asLowercase to match your resolvePartials logic"
    targetTemplate := templateRegistry at: aTemplateName asLowercase ifAbsent: [ 
        Transcript show: 'HTMX Error: Template [', aTemplateName, '] not found in Registry'; cr.
        ^ '<h1>404: Template Not Found</h1><p>The registry does not contain: ', aTemplateName, '</p>' ].
    
    "3. Render the template (which is already a MustacheTemplate object)"
    ^ targetTemplate value: aDictionary
]
