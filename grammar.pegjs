Content = (DocType / Comment / BalancedTag / SelfClosingTag / Text)*

DocType = "<!doctype " doctype:[^>]* ">" {
    return {
        type: 'DocType',
        content: doctype.join('')
    };
}

Comment = "<!--" c:(!"-->" c:. {return c})* "-->" {
    return {
        type: 'Comment',
        content: c.join('')
    };
}

BalancedTag = startTag:StartTag content:Content endTag:EndTag {
    if (startTag.name != endTag) {
        throw new Error("Expected </" + startTag.name + "> but </" + endTag + "> found.");
    }

    return {
      indent: startTag.indent,
      type: 'BalancedTag',
      name: startTag.name,
      attributes: startTag.attributes,
      content: content
    };
  }

SelfClosingTag = "<" name:TagName attributes:Attribute* "/>" {
    return {
      type: 'SelfClosingTag',
      name: name,
      attributes: attributes
    };
  }

StartTag = indent:Indent "<" name:TagName attributes:Attribute* ">" {
  return {
  	indent,
    name,
    attributes
  }
}

EndTag = "</" name:TagName ">" { return name; }

Whitespace = [\n ]+

Indent = breaks:(" "* "\n")* spaces:(" "*) { const blankLines = Math.max(breaks.length -1, 0);  return { blankLines, spaces: spaces.length, hasIndent: breaks.length > 0}}


Attribute = (ValuedAttribute / ValuelessAttribute)

ValuedAttribute = indent:Indent name:AttributeName "=" value:AttributeValue {
  return {
  	indent,
    name: name,
    value: value
  };
}

ValuelessAttribute = Indent name:AttributeName {
  return {
    name: name,
    value: null
  };
}

AttributeName = chars:[a-zA-Z0-9\-]+ { return chars.join(""); }
AttributeValue = (QuotedAttributeValue / UnquotedAttributeValue)

QuotedAttributeValue = value:QuotedString { return value; }

UnquotedAttributeValue = value:decimalDigit* { return value.join(''); }

TagName = chars:[a-zA-Z0-9-]+ { return chars.join(""); }

Text = chars:[^<]+  {
  return {
    type: 'Text',
    content: chars.join("")
  }
}



decimalDigit = [0-9]



QuotedString
  = "\"\"\"" d:(stringData / "'" / $("\"" "\""? !"\""))+ "\"\"\"" {
      return d.join('');
    }
  / "'''" d:(stringData / "\"" / "#" / $("'" "'"? !"'"))+ "'''" {
      return d.join('');
    }
  / "\"" d:(stringData / "'")* "\"" { return d.join(''); }
  / "'" d:(stringData / "\"" / "#")* "'" { return d.join(''); }
  stringData
    = [^"'\\#]
    / "\\0" !decimalDigit { '\0' }
    / "\\0" &decimalDigit { throw new SyntaxError ['string data'], 'octal escape sequence', offset(), line(), column() }
    / "\\b" { '\b' }
    / "\\t" { '\t' }
    / "\\n" { '\n' }
    / "\\v" { '\v' }
    / "\\f" { '\f' }
    / "\\r" { '\r' }
    / "\\" c:. { c }
    / c:"#" !"{" { c }
