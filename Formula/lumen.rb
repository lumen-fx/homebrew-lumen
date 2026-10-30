# Homebrew formula for the Lumen toolchain. It lives in the tap
# lumen-fx/homebrew-lumen as Formula/lumen.rb, which is what
# `brew install lumen-fx/lumen/lumen` reads, and
# .github/workflows/publish-packages.yml pushes this file there on every
# release.
#
# The formula installs the release archive rather than building from source:
# every platform Lumen publishes for already has an archive on the release, and
# building the workspace needs a Rust toolchain the formula would otherwise
# have to pull in.
#
# The three files stay in one directory because lumenc dlopens the runtime
# library from beside its own executable, and `lumenc package` looks for the
# launcher stub in that same directory (public/lumenc/src/link/loader.rs,
# public/lumenc/src/package/package.rs). libexec holds all three and bin gets a
# script that execs the real lumenc, so the running executable is the one in
# libexec no matter how it was invoked. A plain symlink in bin would not do:
# macOS reports the path used to launch, not the resolved one, and the library
# would go missing.
#
# lumen-server, the production server for server-rendered sites, and
# lumen-lsp, the language server the editor integrations start, need nothing
# beside them; they get the same exec script so every command is installed the
# same way. `lumenc web --serve` finds the server beside lumenc in libexec, and
# an editor finds the language server on PATH.
#
# lumen-crash, the crash helper, stays in libexec with no script in bin:
# nobody runs it by hand, and `lumenc package` copies it from beside the
# lumenc it runs as into every package.
#
# Nothing here installs a receipt under share/lumen. That file is what marks a
# copy as installed and turns the built-in update check on
# (public/lumenc/src/package/update_check.rs); without it lumenc never checks for a
# newer release, which is what you want when brew owns the version.
#
# The Linux archives link the distribution's GTK 3, ALSA, and Wayland or X11
# libraries. They are not declared as formula dependencies because the
# binaries look for the system copies, not brewed ones.

class Lumen < Formula
  desc "Toolchain for Lumen, a markup-first UI framework for native desktop apps"
  homepage "https://lumenfx.dev"
  version "0.0.11"
  license "MPL-2.0"

  on_macos do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.11/lumen-macos-aarch64.tar.gz"
      sha256 "177b36697a47205718bf910e697f09dc6377268b6657c080f3d4ab68c11f8ec2"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.11/lumen-macos-x86_64.tar.gz"
      sha256 "b98bb5005374531d496b52ad749be48472900f9ec859a9c1b1e442a073581f89"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.11/lumen-linux-aarch64.tar.gz"
      sha256 "883637acca02422642772f15b1668a3d1822e14258bf8c5d6dc0a8781eea20bb"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.11/lumen-linux-x86_64.tar.gz"
      sha256 "ca293be9a1ad418c049f31e1a05cf7bc4ed80d28312a176e2463970825e585c2"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    libexec.install Dir["bin/*"]
    bin.write_exec_script libexec/"lumenc"
    bin.write_exec_script libexec/"lumen-server"
    bin.write_exec_script libexec/"lumen-lsp"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lumenc --version")
    assert_predicate libexec/"lumen-crash", :executable?

    system bin/"lumenc", "new", "smoke"
    assert_predicate testpath/"smoke/main.lmn", :exist?
    assert_match "ok", shell_output("#{bin}/lumenc check smoke")
  end
end
