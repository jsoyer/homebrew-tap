# Copyright Jerome Soyer
# SPDX-License-Identifier: Apache-2.0

class Libgpod < Formula
  desc "Library for accessing iPod contents"
  homepage "https://web.archive.org/web/20210118214105/http://www.gtkpod.org/libgpod/"
  url "https://downloads.sourceforge.net/project/gtkpod/libgpod/libgpod-0.8/libgpod-0.8.3.tar.bz2"
  sha256 "638a7959d04e95f1e62abad02bd33702e4e8dfef98485ac7d9d50395c37e955d"
  license all_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later"]

  livecheck do
    url "https://sourceforge.net/projects/gtkpod/files/libgpod/"
    regex(%r{href=.*?libgpod[._-]v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "gtk-doc" => :build
  depends_on "intltool" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "gdk-pixbuf"
  depends_on "glib"
  depends_on "libplist"
  depends_on "libpng"
  depends_on "libusb"
  depends_on "sqlite"
  depends_on "taglib"

  def install
    # Create a pkg-config file for libplist compatibility
    # libgpod expects libplist.pc but Homebrew provides libplist-2.0.pc
    pkgconfig_dir = buildpath/"pkgconfig"
    pkgconfig_dir.mkpath
    (pkgconfig_dir/"libplist.pc").write <<~EOS
      prefix=#{Formula["libplist"].opt_prefix}
      exec_prefix=${prefix}
      libdir=${prefix}/lib
      includedir=${prefix}/include

      Name: libplist
      Description: A library to handle Apple Property Lists
      Version: 2.7.0
      Libs: -L${libdir} -lplist-2.0
      Cflags: -I${includedir}
    EOS

    ENV.prepend_path "PKG_CONFIG_PATH", pkgconfig_dir
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libplist"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["glib"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["sqlite"].opt_lib/"pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["gdk-pixbuf"].opt_lib/"pkgconfig"

    system "autoreconf", "-fiv"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--disable-gtk-doc",
                          "--disable-pygobject",
                          "--disable-udev",
                          "--disable-more-warnings",
                          "--without-hal",
                          "--with-python=no",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <gpod/itdb.h>
      int main() {
        Itdb_iTunesDB *db = itdb_new();
        if (db) {
          itdb_free(db);
          return 0;
        }
        return 1;
      }
    C
    system ENV.cc, "test.c", "-o", "test",
           "-I#{include}", "-L#{lib}", "-lgpod",
           "-I#{Formula["glib"].opt_include}/glib-2.0",
           "-I#{Formula["glib"].opt_lib}/glib-2.0/include",
           "-L#{Formula["glib"].opt_lib}", "-lglib-2.0"
    system "./test"
  end
end
