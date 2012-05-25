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
        result << char
      else
        result << sprintf( "\\%03o", ord(char) ) # use an octal code
      end
    end

    result
  end

  def escape_pdf_name(pdf_name)
    result = ''

    pdf_name.each do |char|
      case char[0].ord
      when 33...126 || 0x23 # hash mark
        result << char
      else
        result << sprintf("#%02x", ord(char)) # use a hex code
      end
    end
    return result
  end 

  # In PDF, partial form field names are combined using periods to
  # yield the full form field name; we'll take these dot-delimited
  # names and then expand them into nested arrays, here; takes
  # an array that uses dot-delimited names and returns a tree of arrays;
  #
  def burst_dots_into_arrays(fdf_data_old)
    fdf_data_new = []

    fdf_data_old.each do |key, value|
      key_split = key.to_s.split('.', 2)

      if key_split.count == 2 # handle dot
        if !fdf_data_new.include? key_split[0].to_s
          fdf_data_new[key_split[0].to_s) ] = []
        end

        if fdf_data_new[key_split[0].to_s].class != Array
          # this new key collides with an existing name; this shouldn't happen;
          # associate string value with the special empty key in array, anyhow;

          fdf_data_new[key_split[0].to_s] = 
            { '' => fdf_data_new[key_split[0].to_s)] }
        end

        fdf_data_new[key_split[0].to_s][key_split[1].to_s] = value

      else # no dot
        if fdf_data_new.include? key_split[0].to_s &&
           fdf_data_new[key_split[0].to_s].class == Array
          # this key collides with an existing array; this shouldn't happen;
          # associate string value with the special empty key in array, anyhow;

          fdf_data_new[key.to_s][''] = value

        else # simply copy
          fdf_data_new[key.to_s] = value
      end
    end

    fdf_data_new.each do |key, value|
      if value.class == Array
        fdf_data_new[key.to_s] = burst_dots_into_arrays(value) # recurse
      end
    end

    return fdf_data_new
  end

  def forge_fdf_fields_flags(fdf, field_name, fields_hidden, fields_readonly)
    set = "/SetFf"
    clear = "/ClrFf"
    fdf << fields_hidden.includes(field_name) ? "#{set} 2 " : "#{clear} 2 "
    fdf << fields_readonly.includes(field_name) ? "#{set} 1 " : "#{clear} 1 "
  end

end