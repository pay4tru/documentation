.PHONY: serve build clean install help

help:
	@echo "Comandos disponíveis:"
	@echo "  make serve   - Roda servidor local (http://127.0.0.1:8000)"
	@echo "  make build   - Gera site estático para validação"
	@echo "  make clean   - Remove arquivos gerados"
	@echo "  make install - Instala dependências Python"

serve:
	. venv/bin/activate && mkdocs serve

build:
	. venv/bin/activate && mkdocs build

clean:
	rm -rf site/

install:
	python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt

