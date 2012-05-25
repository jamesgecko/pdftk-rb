# pdftk-ruby
#
# Port of pdftk - https://github.com/andrewheiss/pdftk-php/
# License: Released under New BSD license
#          http://www.opensource.org/licenses/bsd-license.php
#
# Authors: Andrew Heiss (www.andrewheiss.com)
#          Sid Steward (http://www.oreillynet.com/pub/au/1754)

class Pdftk
  def forge_fdf(pdf_form_url, fdf_data_strings, fdf_data_names, fields_hidden,
                fields_readonly)

    # forge_fdf, by Sid Steward
    # version 1.1
    # visit: www.pdfhacks.com/forge_fdf/
    # 
    # PDF can be particular about CR and LF characters, so I spelled them out 
    # in hex: CR == \x0d : LF == \x0a
     

    fdf = "%FDF-1.2\x0d%\xe2\xe3\xcf\xd3\x0d\x0a" # header
    fdf << "1 0 obj\x0d<< " # open the Root dictionary
    fdf << "\x0d/FDF << " # open the FDF dictionary
    fdf << "/Fields [ " # open the form Fields array

    fdf_data_strings = burst_dots_into_arrays( fdf_data_strings )
    forge_fdf_fields_strings(fdf, fdf_data_strings, fields_hidden, fields_readonly)

    fdf_data_names = burst_dots_into_arrays( fdf_data_names )
    forge_fdf_fields_names(fdf, fdf_data_names, fields_hidden, fields_readonly)

    fdf << "] \x0d" # close the Fields array

    # the PDF form filename or URL, if given
    if pdf_form_url
      fdf << "/F (#{ escape_pdf_string($pdf_form_url) }) \x0d"
    end

    fdf << ">> \x0d" # close the FDF dictionary
    fdf << ">> \x0dendobj\x0d" # close the Root dictionary

    # trailer; note the "1 0 R" reference to "1 0 obj" above
    fdf << "trailer\x0d<<\x0d/Root 1 0 R \x0d\x0d>>\x0d"
    fdf << "%%EOF\x0d\x0a"

    return fdf
  end

  def ord(character_string)
    character_string[0].ord
  end

  def escape_pdf_string(pdf_string)
    result = ''

    pdf_string.each do |char|
      case char[0].ord
      when 0x28 || 0x29 || 0x5c # open paren, close paren, backslash
        backslash = 0x5c.chr
        result << backslash << char # escape the character w/ backslash
      when 32...126
        result << sprintf( "\\%03o", ord(char) ) # use an octal code
      else
        result << char
      end
    end

    result
  end


end