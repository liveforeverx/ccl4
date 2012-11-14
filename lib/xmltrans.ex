defmodule Xmltrans do

  defp xmlhead do
    "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
  end

  defp entry_options do
    [{:"xmlns:d", 'http://schemas.microsoft.com/ado/2007/08/dataservices'},
     {:"xmlns:m", 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata'},
     {:"xmlns", 'http://www.w3.org/2005/Atom'}]
  end

  defp updated do
    {:updated, [], ['2009-03-18T11:48:34.9840639-07:00']}
  end

  defp author do
    {:author, [], [{:name, []}]}
  end

  def to_xml content do
    to_xml_default build_xml(content)
  end

  def to_xml_default xml do
    xml = :xmerl.export_simple [xml], :xmerl_xml, [{:prolog, xmlhead}]
    :unicode.characters_to_binary xml
  end

  def build_xml content do
    {:entry, entry_options, [{:title, []}, updated, author, {:id, []}, build_content content]}
  end

  defp build_content content do
    {:content, [{:type, 'application/xml'}], content}
  end

end
