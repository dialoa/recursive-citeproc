FROM pandoc/core:latest

# Uncomment the lines below to customize latex.
# Specify here an archive TeXLive if the pandoc/latex image isn't
# yet updated to the last version.
#
# RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet \
#     && tlmgr install \
#     latex-package-1 \
#     latex-package-2

ENTRYPOINT [ "/usr/local/bin/pandoc" ]