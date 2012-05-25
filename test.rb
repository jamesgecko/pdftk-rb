require 'test/unit'
require 'pdftk'

class TestPdftk < Test::Unit::TestCase
  def test_escape_pdf_name
    a = Pdftk.new
    assert_equal '#', a.escape_pdf_name('#')
    assert_equal '#20', a.escape_pdf_name(' ')
  end

  def test_burst_dots_into_arrys
  end

  def test_forge_fdf_fields_flags
  end

  def test_forge_fdf
    a = Pdftk.new
    b = { CompanyPhone: '1234567890' }
    expected = "%FDF-1.2\x0d%\xe2\xe3\xcf\xd3\x0d\x0a1 0 obj\x0d<< " +
    "\x0d/FDF << /Fields [ " +
    #forge_fdf_fields
    "<< /T (CompanyPhone) /V (1234567890) " +
    "/ClrFf 2 /ClrFf 1 " +
    ">> \x0d" +
    "] \x0d" + # close the Fields array
    ">> \x0d>> \x0dendobj\x0d" + # close the FDF disctionary and root dictionary
    "trailer\x0d<<\x0d/Root 1 0 R \x0d\x0d>>\x0d" + # trailer
    "%%EOF\x0d\x0a"
    result = a.forge_fdf '', b, {}, {}, {}
    assert_equal expected, result
  end
end