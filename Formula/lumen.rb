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
  version "0.0.10"
  license "MPL-2.0"

  on_macos do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.10/lumen-macos-aarch64.tar.gz"
      sha256 "4151f2ab6829da80c2b95f1976554441e6257f3637d9e8332fb9f6d2a584de80"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.10/lumen-macos-x86_64.tar.gz"
      sha256 "9e1680eaa4b690569464a12de8462c5f563ee9fec6b9f8025cb517668258e8d7"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.10/lumen-linux-aarch64.tar.gz"
      sha256 "ab6f1e2e88d91ca58eb001b398f89d31fd830e1ab93bbd6af301dec1edeeac5f"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.10/lumen-linux-x86_64.tar.gz"
      sha256 "c4fb1df2b7a9b2acf0374e53c7dd436a90d42ab33a33a072e8558d752c51c1fa"
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

    system bin/"lumenc", "new", "smoke"
    assert_predicate testpath/"smoke/main.lmn", :exist?
    assert_match "ok", shell_output("#{bin}/lumenc check smoke")
  end
end
