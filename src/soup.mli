(* This file is part of Lambda Soup, released under the 2-clause BSD license.
   See LICENSE.md for details, or visit
   https://github.com/aantron/lambda-soup. *)

(** Easy functional HTML scraping and manipulation.

    Lambda Soup is an HTML data extraction and analysis library. It supports CSS
    selectors, DOM traversals, mutation, and HTML output. This very documentation
    page was generated by [ocamldoc] and then
    {{:https://github.com/aantron/lambda-soup/blob/master/docs/postprocess.ml}
    rewritten} by Lambda Soup!

    Here are some usage examples:

{[
open Soup

let soup = read_channel stdin |> parse in

(* Print the page title. *)
soup $ "title" |> R.leaf_text |> print_endline;

(* Print the targets of all links. *)
soup $$ "a[href]"
|> iter (fun a -> print_endline (R.attribute "href" a));

(* Find the first unordered list. *)
let ul = soup $ "ul" in

(* Print the contents of all its items. *)
ul $$ "li"
|> iter (fun li ->
  trimmed_texts li |> String.concat "" |> print_endline)

(* Find all subsequent sibling elements of the same list. *)
let _ = ul $$ "~ *" in

(* Find all previous sibling elements instead. *)
let _ = ul |> previous_siblings |> elements in

(* ... *)
]}

    Lambda Soup is based around two kind of values: {e nodes}, which represent
    HTML elements, text content, and so on, and {e traversals}, which are lazy
    sequences of nodes. The top-level node is the {e soup node} (a.k.a. document
    node), which you typically get by calling {!parse} on a string containing
    HTML.

    Once you have a node, you call {!select} on it to traverse to other nodes
    using CSS. There are also specialized functions, such as {!ancestors} and
    {!previous_siblings}, which allow you to traverse in directions that CSS
    cannot express.

    Traversals can be manipulated with familiar combinators such as {!map},
    {!fold}, and {!filter}. They can also be terminated early.

    Once you have traversed to a node you are interested in, you can extract its
    content or attributes, mutate it, cause other side effects, begin another
    traversal, or do anything else your application requires. Enjoy!

    Lambda Soup is developed on {{:https://github.com/aantron/lambda-soup}
    GitHub} and distributed under the
    {{:https://github.com/aantron/lambda-soup/blob/master/LICENSE.md} BSD
    license}.

    This documentation page is for version 0.6.1 of the library. Documentation
    for other versions can be downloaded from the
    {{:https://github.com/aantron/lambda-soup/releases} releases page}. *)



(** {2 Types} *)

type element
type general
type soup
(** "Phantom" types for use with ['a node]. See explanation below. *)

type 'a node
(** HTML nodes. These come in three varieties: [element node] represents a node
    that is known to be an element, [soup node] represents an entire document,
    and [general node] represents a node that might be anything, including an
    element, a document, or text. There is no phantom type specifically for text
    nodes.

    Throughout Lambda Soup, if a function can operate on any kind of node, the
    argument is typed at ['a node]. If an element node or the entire document is
    required, the argument type is [element node] or [soup node],
    respectively. [general node] is the result of a function that can't
    guarantee that it evaluates to only elements or only documents. *)

type 'a nodes
(** Sequence of nodes. This is always instantiated as either [element nodes] or
    or [general nodes]. The sequence is {e lazy} in the sense that only as many
    elements as needed are evaluated. This can be used with {!with_stop} to
    traverse part of a document until some condition is met. *)



(** {2 High-level interface} *)

val parse : string -> soup node
(** Parses the given HTML and produces a document node. Entity references are
    resolved. The character encoding is detected automatically.

    If you need to parse XML, want finer control over parsing, or want to feed
    Lambda Soup something other than bytes, see {{:#2_Parsingsignals} Parsing
    signals}. *)

val select : string -> (_ node) -> element nodes
(** [select selector node] is all the descendants of [node] matching CSS
    selector [selector]. All
    {{:http://www.w3.org/TR/selectors/#selectors} CSS3 selectors} are
    supported, except those which imply layout or a user interface:

{[
:link, :visited, :hover, :active, :focus, :target, :lang, :enabled,
:disabled, :checked, :indeterminate, ::first-line, ::first-letter,
::selection, ::before, ::after
]}

    XML namespace selectors are not supported. Lambda Soup supports the canceled
    {{:http://www.w3.org/TR/2001/CR-css3-selectors-20011113/#content-selectors}
    [:contains("foo")]} pseudo-class.

    In regular CSS, a selector cannot start with a combinator such as [>].
    Lambda Soup allows selectors such as [> p], [+ p], and [~ p], which select
    immediate children of [node], adjacent next siblings, and all next siblings,
    respectively.

    In addition, you can use the empty selector to select [node] itself. In this
    case, note that if [node] is not an element (for example, it is often the
    soup node), [select] will result in nothing: [select] always results in
    sequences of {e element} nodes only. *)

val select_one : string -> (_ node) -> element node option
(** Like [select], but evaluates to at most one element. Note that there is also
    [R.select_one] if you don't want an optional result, which is explained at
    {!require}. *)

val ($$) : (_ node) -> string -> element nodes
(** [node $$ selector] is the same as [select selector node]. *)

val ($?) : (_ node) -> string -> element node option
(** [node $? selector] is the same as [select_one selector node]. *)

val ($) : (_ node) -> string -> element node
(** [node $ selector] is the same as [select_one selector node |> require]. *)

(** Open [Soup.Infix] instead of [Soup] to introduce only the infix operators
    [$$], [$?], and [$] into your scope. *)
module Infix :
sig
  val ($) : (_ node) -> string -> element node
  val ($?) : (_ node) -> string -> element node option
  val ($$) : (_ node) -> string -> element nodes
end


(** {2 Options} *)

val require : 'a option -> 'a
(** [require (Some v)] evaluates to [v], and [require None] raises [Failure]. *)

(** For each function [Soup.f] that evaluates to an option, [Soup.R.f] is a
    version of [f] that is post-composed with [require], so, for example, you
    can write [soup |> children |> R.first] instead of
    [soup |> children |> first |> require]. *)
module R :
sig
  val select_one : string -> (_ node) -> element node
  val attribute : string -> element node -> string
  val id : element node -> string
  val element : (_ node) -> element node
  val leaf_text : (_ node) -> string
  val nth : int -> 'a nodes -> 'a node
  val first : 'a nodes -> 'a node
  val last : 'a nodes -> 'a node
  val tag : string -> (_ node) -> element node
  val parent : (_ node) -> element node
  val child : (_ node) -> general node
  val child_element : (_ node) -> element node
  val next_sibling : (_ node) -> general node
  val previous_sibling : (_ node) -> general node
  val next_element : (_ node) -> element node
  val previous_element : (_ node) -> element node
end



(** {2 Early termination} *)

type 'a stop = {throw : 'b. 'a -> 'b}
(** Used for early termination. See {!with_stop} below. *)

val with_stop : ('a stop -> 'a) -> 'a
(** [with_stop (fun stop -> e)] behaves as [e]. However, if the evaluation of
    [e] calls [stop.throw v], the whole expression immediately evaluates to [v]
    instead.

    For example, here is an expression that finds the first node with a
    [draggable] attribute, stopping traversal immediately when that occurs:

{[
with_stop (fun stop ->
  some_root_node
  |> descendants
  |> elements
  |> iter (fun element ->
    if has_attribute "draggable" element then
      stop.throw (Some element));
  None)
]} *)



(** {2 Element access} *)

val name : element node -> string
(** The element's tag name. For example, an [<a>] element has tag name [a]. All
    tag names are converted to lowercase. *)

val attribute : string -> element node -> string option
(** [attribute attr element] retrieves the value of attribute [attr] from the
    given element. *)

val classes : element node -> string list
(** The element's class list. For example, [<a class="foo bar">] has class list
    [["foo"; "bar"]]. *)

val id : element node -> string option
(** The element's id. *)

val has_attribute : string -> element node -> bool
(** [has_attribute attr element] indicates whether [element] has attribute
    [attr]. *)

val fold_attributes : ('a -> string -> string -> 'a) -> 'a -> element node -> 'a
(** [fold_attributes f init element] applies [f] successively to the names and
    values of the attributes of [element]. The first [string] argument to [f] is
    the attribute name, and the second is the value. *)

val element : (_ node) -> element node option
(** Given any node, asserts that it is an element [e]. If so, evaluates to
    [Some e]. Otherwise, evaluates to [None]. *)

val elements : (_ nodes) -> element nodes
(** Filters non-elements from a sequence of nodes. *)

val is_element : (_ node) -> bool
(** Indicates whether the given node is an element. *)



(** {2 Content access} *)

val texts : (_ node) -> string list
(** [texts node] is the content of all text nodes that are descendants of
    [node]. If [node] is itself a text node, evaluates to [node]'s content. *)

val trimmed_texts : (_ node) -> string list
(** Same as {!texts}, but all strings are passed through [String.trim], and then
    all empty strings are filtered out. *)

val leaf_text : (_ node) -> string option
(** [leaf_text node] retrieves the content of one text node in [node]:

    - If [node] is a text node itself, with value [s], [leaf_text node]
      evaluates to [Some s].
    - If [node] is an element or soup node, then, [leaf_text node] filters out
      all text children of [node] containing only whitespace. If there is only
      one child [child] remaining, it evaluates to [leaf_text child]. If there
      are no children remaining, it evaluates to [Some ""]. If there are two or
      more children remaining, it evaluates to [None].
    
    Here are some examples of what [leaf_text] produces for various nodes:

{[
some text                                =>   Some "some text"
<p>some text</p>                         =>   Some "some text"
<div><p>some text</p></div>              =>   Some "some text"
<div> <p>some text</p></div>             =>   Some "some text"
<div><p>some text</p><p>more</p></div>   =>   None
<div></div>                              =>   Some ""
]}

 *)



(** {2 Elementary traversals} *)

val children : (_ node) -> general nodes
(** [children node] is the sequence of all children of [node]. If [node] is a
    text node, the traversal is empty. *)

val descendants : (_ node) -> general nodes
(** [descendants node] is the sequence of all descendants of [node]. [node] is
    not considered to be its own descendant. If [node] is a text node, the
    traversal is empty. *)

val ancestors : (_ node) -> element nodes
(** [ancestors node] is the sequence of all ancestors of [node]. [node] is not
    considered to be its own ancestor. The soup node is not included. Ancestors
    are ordered by proximity to [node], i.e. the sequence goes up the DOM tree
    to a root element. *)

val siblings : (_ node) -> general nodes
(** [siblings node] is the sequence of all siblings of [node]. [node] is not
    considered to be its own sibling. The siblings are ordered as they appear in
    the child list of [node]'s parent. *)

val next_siblings : (_ node) -> general nodes
(** Like {!siblings}, but only those siblings which follow [node] in its
    parent's child list. *)

val previous_siblings : (_ node) -> general nodes
(** Like {!siblings}, but only those siblings which precede [node] in its
    parent's child list, and ordered by proximity to [node], i.e. the reverse
    order of appearance in [node]'s parent's child list. *)



(** {2 Combinators} *)

val fold : ('a -> 'b node -> 'a) -> 'a -> 'b nodes -> 'a
(** [fold f init s] folds [f] over the nodes of [s], i.e. if [s] is
    [n, n', n'', ...], evaluates [f (f (f init n) n') n'' ...]. *)

val filter : ('a node -> bool) -> 'a nodes -> 'a nodes
(** [filter f s] is the sequence consisting of the nodes [n] of [s] for which
    [f n] evaluates to [true]. *)

val map : ('a node -> 'b node) -> 'a nodes -> 'b nodes
(** [map f s] is the sequence consisting of nodes [f n] for each node [n] of
    [s]. *)

val filter_map : ('a node -> 'b node option) -> 'a nodes -> 'b nodes
(** [filter_map f s] is the sequence consisting of nodes [n'] for each node [n]
    of [s] for which [f n] evaluates to [Some n']. Nodes for which [f n]
    evaluates to [None] are dropped. *)

val flatten : ('a node -> 'b nodes) -> 'a nodes -> 'b nodes
(** [flatten f s] is the sequence consisting of the concatenation of all the
    sequences [f n] for each [n] in [s]. *)

val iter : ('a node -> unit) -> 'a nodes -> unit
(** [iter f s] applies [f] to each node in [s]. *)

val rev : 'a nodes -> 'a nodes
(** Reverses the given node sequence. Note that this forces traversal of the
    sequence. *)

val to_list : 'a nodes -> 'a node list
(** Converts the given node sequence to a list. *)



(** {2 Projection} *)

val nth : int -> 'a nodes -> 'a node option
(** [nth n s] evaluates to the [n]th member of [s], if it is present. The index
    is 1-based. This is for consistency with the CSS [:nth-child] selectors. *)

val first : 'a nodes -> 'a node option
(** Evaluates to the first node of the given sequence. *)

val last : 'a nodes -> 'a node option
(** Evaluates the entire given sequence and returns the last node. *)

val count : 'a nodes -> int
(** Evaluates the entire given sequence and then returns the number of nodes. *)

val index_of : (_ node) -> int
(** Evaluates to the index of the given node in its parent's child list. If the
    node has no parent, the index is 1. The index is 1-based, according to CSS
    convention. *)

val index_of_element : element node -> int
(** Evaluates to the element index of the given element in the parent's child
    list. That is, the index of the given element when the parent's non-element
    children are disregarded. The index is 1-based, according to CSS
    convention. *)



(** {2 Convenience} *)

val tags : string -> (_ node) -> element nodes
(** Evaluates to all descendant elements of the given node that have the given
    tag name. For example, [some_root_node |> tags "a"] is a sequence of all [a]
    elements under [some_root_node]. It is equivalent to

{[
some_root_node
|> descendants |> elements |> filter (fun e -> name e = "a")
]}

    and

{[
some_root_node $$ "a"
]}

    Tag names are case-insensitive. *)

val tag : string -> (_ node) -> element node option
(** Like {!tags}, but evaluates to only the first element. *)

val parent : (_ node) -> element node option
(** Given a node, evaluates to its parent element, if it has one. Note that root
    nodes do not have a parent {e element}, as their parent is the soup node.
    Equivalent to [n |> ancestors |> first]. *)

val is_root : (_ node) -> bool
(** Indicates whether the given node is not a soup node, and either has no
    parent, or its parent is a soup node. *)

val child : (_ node) -> general node option
(** [child node] evaluates to [node]'s first child. Equivalent to
    [node |> children |> first]. *)

val child_element : (_ node) -> element node option
(** [child_element node] evaluates to [node]'s first child element. Equivalent
    to [node |> children |> elements |> first]. *)

val next_sibling : (_ node) -> general node option
(** [next_sibling node] is the next sibling of [node] in [node]'s parent's child
    list. Equivalent to [node |> next_siblings |> first]. *)

val previous_sibling : (_ node) -> general node option
(** Like {!next_sibling}, but for the preceding sibling instead. *)

val next_element : (_ node) -> element node option
(** [next_element node] is the next sibling of [node] that is an element.
    Equivalent to [n |> next_siblings |> elements |> first]. *)

val previous_element : (_ node) -> element node option
(** Like {!next_element}, but for the preceding siblings instead. *)

val no_children : (_ node) -> bool
(** Indicates whether the given node has no child nodes. *)

val at_most_one_child : (_ node) -> bool
(** Indicates whether the given node has at most one child node. *)



(** {2 Printing} *)

val to_string : (_ node) -> string
(** Converts the node tree rooted at the given node to an HTML5 string,
    preserving whitespace nodes. *)

val pretty_print : (_ node) -> string
(** Converts the node tree rooted at the given node to an HTML5 string formatted
    for easy reading by humans, difference algorthims, etc.

    Note that this can change the whitespace structure of the HTML, so it may
    display differently in a browser than the original parsed document. *)



(** {2 Parsing signals}

    Lambda Soup uses {{: https://github.com/aantron/markup.ml} Markup.ml}
    internally to parse and write markup. If you wish to:

    - scrape HTML output of some process without first writing it to a string,
    - scrape XML,
    - have fine control over how parsing is done, such as encoding selection, or
    - run the input or output of Lambda Soup through streaming filters,

    then you should use the functions below instead of {!parse} and
    {!to_string}.

    See the {{:http://aantron.github.io/markup.ml/} Markup.ml documentation} for
    a description of the types involved. The
    {{:https://github.com/aantron/markup.ml#overview-and-basic-usage} Markup.ml
    overview} may be a good place to start.
 *)

val signals : (_ node) -> (Markup.signal, Markup.sync) Markup.stream
(** Converts the node tree rooted at the given node to a stream of Markup.ml
    signals. This underlies {!to_string} and {!pretty_print}.

    For example, you can use this function together with
    {{:http://aantron.github.io/markup.ml/#VALwrite_xml} [Markup.write_xml]} to
    output XML, instead of HTML:

{[
soup |> signals |> Markup.write_xml |> Markup.to_string
]} *)

val from_signals : (Markup.signal, Markup.sync) Markup.stream -> soup node
(** Converts a stream of Markup.ml signals to a Lambda Soup document. This
    underlies {!parse}.

    For example, you can use this function together with
    {{:http://aantron.github.io/markup.ml/#VALparse_xml} [Markup.parse_xml]} to
    load XML into Lambda Soup:

{[
Markup.string s |> Markup.parse_xml |> Markup.signals |> from_signals
]}

    Namespaces are ignored at the moment. *)



(** {2 Equality} *)

val equal : (_ node) -> (_ node) -> bool
(** [equal n n'] recursively tests the node trees rooted at [n] and [n'] for
    equality. To test [true], the trees must be identical, including whitespace
    text nodes. Class attributes and other multi-valued attributes are compared
    literally: classes must be listed in the same order, with the same amount of
    whitespace in the attribute value. For the purposes of comparison, adjacent
    text nodes are merged, and empty text nodes are ignored: this is the
    standard HTML normalization procedure. *)

val equal_modulo_whitespace : (_ node) -> (_ node) -> bool
(** [equal_modulo_whitespace n n'] is like [equal n n'], but all text nodes have
    their values passed through [String.trim]. Text nodes that become empty are
    then ignored for the purpose of comparison, as in [equal]. *)



(** {2 Mutation} *)

val create_element :
  ?id:string ->
  ?class_:string ->
  ?classes:string list ->
  ?attributes:(string * string) list ->
  ?inner_text:string ->
  string ->
    element node
(** [create_element tag] creates a new element with the name [tag].

    If [~attributes] is specified, the given attributes are added to the
    element. [~attributes] defaults to [[]].

    If [~classes] is specified, the class names are concatenated into a single
    string [s] and the [class] attribute is set on the element to the resulting
    value. This takes precedence over [~attributes].

    If [~class] is specified, the class is set on the element. This takes
    precedence over both [~attributes] and [~classes].

    If [~id] is specified, the id is set. This takes precedence over
    [~attributes].

    If [~inner_text] is specified, a text node is created with the given string,
    and made the single child of the new element. *)

val create_text : string -> general node
(** Creates a new text node with the given content. *)

val create_soup : unit -> soup node
(** Creates a new empty document node. *)

val append_child : element node -> (_ node) -> unit
(** [append_child element node] adds [node] to the end of the child list of
    [element]. *)

val prepend_child : element node -> (_ node) -> unit
(** [prepend_child element node] adds [node] to the beginning of the child list
    of [element]. *)

val insert_at_index : int -> element node -> (_ node) -> unit
(** [insert_at_index k element node] makes [node] the [k]th child of [element].
    Note that the index is 1-based. If [k] is outside the range of current valid
    indices, [node] is inserted at the beginning or end of [element]'s child
    list. *)

val insert_before : (_ node) -> (_ node) -> unit
(** [insert_before node node'] inserts [node'] immediately before [node] in
    [node]'s parent's child list. *)

val insert_after : (_ node) -> (_ node) -> unit
(** [insert_after node node'] inserts [node'] immediately after [node] in
    [node]'s parent's child list. *)

val delete : (_ node) -> unit
(** Deletes the given node by unlinking it from its parent. If the node has
    descendants, they are implicitly deleted by this operation as well, in the
    sense that they become unreachable from the parent. *)

val clear : (_ node) -> unit
(** Unlinks all children of the given node. *)

val replace : (_ node) -> (_ node) -> unit
(** [replace node node'] replaces [node] with [node'] in [node]'s parent's child
    list. All descendants of [node] are implicitly deleted by this operation,
    because they become unreachable from [node]'s parent. *)

val swap : element node -> element node -> unit
(** [swap element element'] replaces [element] with [element'] in [element]'s
    parent's child list. All children of [element] are transferred to
    [element'], and all original children of [element'] are transferred to
    [element]. *)

val wrap : (_ node) -> element node -> unit
(** [wrap node element] inserts [element] in the place of [node], and then makes
    [node] [element]'s child. All original children of [element] are
    unlinked. *)

val unwrap : (_ node) -> unit
(** [unwrap node] unlinks [node], and inserts all of [node]'s children as
    children of [node]'s parent at the former location of [node]. *)

val append_root : soup node -> (_ node) -> unit
(** [append_root soup node] adds [node] as the last root node of [soup]. *)

val set_name : string -> element node -> unit
(** Sets the tag name of the given element. *)

val set_attribute : string -> string -> element node -> unit
(** [set_attribute attr value element] sets the value of attribute [attr] on
    [element] to [value]. If the attribute is not present, it is added to
    [element]. If it is already present, the value is replaced. *)

val delete_attribute : string -> element node -> unit
(** Removes the given attribute from the given element. If the attribute is not
    present, has no effect. *)

val add_class : string -> element node -> unit
(** [add_class c element] adds class [c] to [element], if [element] does not
    already have class [c]. *)

val remove_class : string -> element node -> unit
(** [remove_class c element] removes class [c] from [element], if [element] has
    class [c]. *)



(** {2 I/O}

    Lambda Soup is not an I/O library. However, it provides a few simple helpers
    based on standard I/O functions in
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Pervasives.html#6_Inputoutput}
    [Pervasives]}. These should not be used for "serious" code. They are only
    for when you need to get something done quickly, and/or don't care about
    corner cases, concurrency, or excellent reliability. In such cases, they
    allow you to avoid writing I/O wrappers or using additional libraries.

    Using these, you can write little command-line scrapers and filters:

{[
let () =
  let soup = read_channel stdin |> parse in
  let () = (* ...do things to soup... *) in
  soup |> to_string |> write_channel stdout
]}

    If the above is compiled to a file [scrape], you can then run

{[
curl -L "http://location.com" | ./scrape
]} *)

val read_file : string -> string
(** Reads the entire contents of the file with the given path. Raises
    [Sys_error] on failure. *)

val read_channel : in_channel -> string
(** Reads all bytes from the given channel. *)

val write_file : string -> string -> unit
(** [write_file path data] writes [data] to the file given by [path]. If the
    file already exists, it is truncated (erased). If you want to append to
    file, use
    {{: http://caml.inria.fr/pub/docs/manual-ocaml/libref/Pervasives.html#VALopen_out_gen}
    [open_out_gen]} with the necessary flags, and pass the resulting channel to
    [write_channel]. Raises [Sys_error] on failure. *)

val write_channel : out_channel -> string -> unit
(** Writes the given data to the given channel. *)
