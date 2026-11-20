class Mdpeek < Formula
  include Language::Python::Virtualenv

  desc "Progressive exposure for markdown: navigate large documents by section"
  homepage "https://github.com/jongracecox/mdpeek"
  url "https://files.pythonhosted.org/packages/ac/fa/1748fae1345212c92901c93acaa0d049c7cb51e1a88b395e1007a6d08a0c/mdpeek-0.0.1.tar.gz"
  sha256 "14f6916c55a1e18a1aeb370c1f9f89973275acc03512d2e3405d10981963b4fa"
  license "MIT"

  depends_on "python@3.14"

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/16/fc/cee2c45553c9a9bf77d8b0c391560c556d7ed756b1f0bb35eb5d48db09ea/markdown_it_py-4.3.0.tar.gz"
    sha256 "91a58fa5b72c71a40cf7177250fd767480d7a2bb3ac426ccfb76fb90305fdaaa"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/d6/54/cfe61301667036ec958cb99bd3efefba235e65cdeb9c84d24a8293ba1d90/mdurl-0.1.2.tar.gz"
    sha256 "bb413d29f5eea38f31dd4754dd7377d4465116fb207585f97bf925588687c1ba"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mdpeek --version")

    (testpath/"guide.md").write <<~MARKDOWN
      # Guide

      Intro.

      ## Setup

      Install it.

      ## Prices

      | Item | Price |
      |---|---|
      | tea | 2.5 |
      | cake | 4 |
    MARKDOWN

    outline = shell_output("#{bin}/mdpeek guide.md")
    assert_match "[S1] Guide", outline
    assert_match "[S1.2] Prices (4 lines, 1 table)", outline

    section = shell_output("#{bin}/mdpeek guide.md -s S1.2")
    assert_match "| tea | 2.5 |", section

    sql = "select item from t1 where price > 3"
    assert_equal "item\ncake\n",
                 shell_output("#{bin}/mdpeek guide.md --engine sqlite --sql '#{sql}' --format csv")
  end
end
