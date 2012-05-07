CodeMirror.defineMode("markdown",function(a,b){function t(a,b,c){return b.f=b.inline=c,c(a,b)}function u(a,b,c){return b.f=b.block=c,c(a,b)}function v(a,b){if(a.match(r))return a.skipToEnd(),e;if(a.eatSpace())return null;if(a.peek()==="#"||a.match(q))return a.skipToEnd(),d;if(a.eat(">"))return b.indentation++,f;if(a.peek()==="[")return t(a,b,C);if(n.test(a.peek())){var c=new RegExp("(?:s*["+a.peek()+"]){3,}$");if(a.match(c,!0))return h}var i;return(i=a.match(o,!0)||a.match(p,!0))?(b.indentation+=i[0].length,g):t(a,b,b.inline)}function w(a,b){var d=c.token(a,b.htmlState);return d==="tag"&&b.htmlState.type!=="openTag"&&!b.htmlState.context&&(b.f=z,b.block=v),d}function x(a){return a.strong?a.em?m:l:a.em?k:null}function y(a,b){return a.match(s,!0)?x(b):undefined}function z(a,b){var c=b.text(a,b);if(typeof c!="undefined")return c;var d=a.next();if(d==="\\")return a.next(),x(b);if(d==="`")return t(a,b,F(e,"`"));if(d==="[")return t(a,b,A);if(d==="<"&&a.match(/^\w/,!1))return a.backUp(1),u(a,b,w);var f=x(b);return d==="*"||d==="_"?a.eat(d)?(b.strong=!b.strong)?x(b):f:(b.em=!b.em)?x(b):f:x(b)}function A(a,b){while(!a.eol()){var c=a.next();c==="\\"&&a.next();if(c==="]")return b.inline=b.f=B,i}return i}function B(a,b){a.eatSpace();var c=a.next();return c==="("||c==="["?t(a,b,F(j,c==="("?")":"]")):"error"}function C(a,b){return a.match(/^[^\]]*\]:/,!0)?(b.f=D,i):t(a,b,z)}function D(a,b){return a.eatSpace(),a.match(/^[^\s]+/,!0),b.f=b.inline=z,j}function E(a){return E[a]||(E[a]=new RegExp("^(?:[^\\\\\\"+a+"]|\\\\.)*(?:\\"+a+"|$)")),E[a]}function F(a,b,c){return c=c||z,function(d,e){return d.match(E(b)),e.inline=e.f=c,a}}var c=CodeMirror.getMode(a,{name:"xml",htmlMode:!0}),d="header",e="comment",f="quote",g="string",h="hr",i="link",j="string",k="em",l="strong",m="emstrong",n=/^[*-=_]/,o=/^[*-+]\s+/,p=/^[0-9]\.\s+/,q=/^(?:\={3,}|-{3,})$/,r=/^(k:\t|\s{4,})/,s=/^[^\[*_\\<>`]+/;return{startState:function(){return{f:v,block:v,htmlState:c.startState(),indentation:0,inline:z,text:y,em:!1,strong:!1}},copyState:function(a){return{f:a.f,block:a.block,htmlState:CodeMirror.copyState(c,a.htmlState),indentation:a.indentation,inline:a.inline,text:a.text,em:a.em,strong:a.strong}},token:function(a,b){if(a.sol()){b.f=b.block;var c=b.indentation,d=0;while(c>0)if(a.eat(" "))c--,d++;else if(c>=4&&a.eat("\t"))c-=4,d+=4;else break;b.indentation=d;if(d>0)return null}return b.f(a,b)},getType:x}}),CodeMirror.defineMIME("text/x-markdown","markdown")