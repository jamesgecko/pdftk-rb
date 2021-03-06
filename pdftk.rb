class Pdftk
  def forge_fdf(pdf_form_url, fdf_data_strings, fdf_data_names, fields_hidden,
                fields_readonly)

    # PDF can be particular about CR and LF characters, so I spelled them out 
    # in hex: CR == \x0d : LF == \x0a
    fdf = "%FDF-1.2\x0d%\xe2\xe3\xcf\xd3\x0d\x0a" # header
    fdf << "1 0 obj\x0d<< " # open the Root dictionary
    fdf << "\x0d/FDF << " # open the FDF dictionary
    fdf << "/Fields [ " # open the form Fields array

    fdf_data_strings = burst_dots_into_arrays( fdf_data_strings )
    forge_fdf_fields(fdf, fdf_data_strings, fields_hidden, fields_readonly, :string)

    fdf_data_names = burst_dots_into_arrays( fdf_data_names )
    forge_fdf_fields(fdf, fdf_data_names, fields_hidden, fields_readonly, :name)

    fdf << "] \x0d" # close the Fields array

    # the PDF form filename or URL, if given
    if !pdf_form_url.empty?
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

    pdf_string.each_char do |char|
      case ord(char)
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

    pdf_name.each_char do |char|
      case ord(char)
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
    fdf_data_new = {}

    fdf_data_old.each do |key, value|
      key1, key2 = key.to_s.split('.', 2)

      if !key2.nil? # handle dot
        if !fdf_data_new.include? key1
          fdf_data_new[key1] = {}
        end

        if fdf_data_new[key1].class != Hash
          # this new key collides with an existing name; this shouldn't happen;
          # associate string value with the special empty key in array, anyhow;

          fdf_data_new[key1] = { '' => fdf_data_new[key1] }
        end

        fdf_data_new[key1][key2] = value

      else # no dot
        if fdf_data_new[key1].class == Hash
          # this key collides with an existing array; this shouldn't happen;
          # associate string value with the special empty key in array, anyhow;

          fdf_data_new[key][''] = value

        else # simply copy
          fdf_data_new[key] = value
        end
      end
    end

    fdf_data_new.each do |key, value|
      if value.class == Hash
        fdf_data_new[key] = burst_dots_into_arrays(value) # recurse
      end
    end

    return fdf_data_new
  end

  def forge_fdf_fields_flags(fdf, field_name, fields_hidden, fields_readonly)
    set = "/SetFf"
    clear = "/ClrFf"
    fdf << (fields_hidden.include?(field_name) ? "#{set} 2 " : "#{clear} 2 ")
    fdf << (fields_readonly.include?(field_name) ? "#{set} 1 " : "#{clear} 1 ")
  end

  def forge_fdf_fields(fdf, fdf_data, fields_hidden, fields_readonly,
    fdf_data_type, accumulated_name='')
    # if fdf_data_type contains :string, fdf_data contains string data
    # if fdf_data_type contains :name, fdf_data contains name data
    #
    # string data is used for text fields, combo boxes and list boxes;
    # name data is used for checkboxes and radio buttons, and
    # /Yes and /Off are commonly used for true and false

    accumulated_name << '.' if accumulated_name.length > 0 # append period seperator

    fdf_data.each do |key, value|
      # we use string casts to prevent numeric strings from being silently converted to numbers

      fdf << "<< " # open dictionary

      if value.class == Hash # parent; recurse
        fdf << "/T (" + escape_pdf_string(key.to_s) + ") " # partial field name
        fdf << "/Kids [ "                                  # open Kids array

        # recurse
        forge_fdf_fields(fdf, value, fields_hidden, fields_readonly,
          fdf_data_type, accumulated_name + key.to_s)

        fdf << "] " # close Kids array
      else
        # field name
        fdf << "/T (#{ escape_pdf_string(key.to_s) }) "

        # field value
        case fdf_data_type
        when :string
          fdf << "/V (#{ escape_pdf_string(value.to_s) }) "
        when :name
          fdf << "/V /#{ escape_pdf_name(value.to_s) } "
        else
          raise "Invalid fdf_data_type value"
        end

        # field flags
        forge_fdf_fields_flags(fdf,
              accumulated_name + key.to_s,
              fields_hidden,
              fields_readonly)
      end
      fdf << ">> \x0d" # close dictionary

    end
  end
end