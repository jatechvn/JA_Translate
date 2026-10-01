"""Build-time preparation of official Helsinki OPUS-MT packs (not app runtime)."""
import argparse, hashlib, json, pathlib, urllib.request

MODELS = {pair: f'Helsinki-NLP/opus-mt-{pair}' for pair in ['en-vi', 'vi-en', 'en-zh', 'zh-en']}
FILES = ['README.md', 'config.json', 'generation_config.json', 'tokenizer_config.json', 'vocab.json', 'source.spm', 'target.spm', 'pytorch_model.bin']

def prepare(pair, root, download_only=False):
    repo = MODELS[pair]
    with urllib.request.urlopen(f'https://huggingface.co/api/models/{repo}', timeout=30) as response:
        metadata = json.load(response)
    revision = metadata['sha']
    source = root / '.local_ai_tools' / 'opus_sources' / pair
    source.mkdir(parents=True, exist_ok=True)
    revision_file = source / 'source_revision.txt'
    if revision_file.is_file():
        revision = revision_file.read_text(encoding='utf-8').strip()
    else:
        revision_file.write_text(revision, encoding='utf-8')
    for name in FILES:
        target = source / name
        if target.is_file() and target.stat().st_size:
            continue
        url = f'https://huggingface.co/{repo}/resolve/{revision}/{name}?download=true'
        print(f'{pair}: downloading {name}', flush=True)
        try:
            with urllib.request.urlopen(url, timeout=120) as response, open(str(target) + '.part', 'wb') as output:
                total = int(response.headers.get('Content-Length', '0'))
                received = 0
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
                    received += len(chunk)
                if total and received != total:
                    raise RuntimeError(f'Incomplete file: {name}')
            pathlib.Path(str(target) + '.part').replace(target)
        except urllib.error.HTTPError as error:
            if name in ['generation_config.json', 'tokenizer_config.json'] and error.code == 404:
                continue
            raise
    if download_only:
        return
    import shutil
    import ctranslate2
    destination = root / 'models' / 'opus-mt' / pair
    if destination.exists():
        if not (destination / 'manifest.json').is_file():
            raise RuntimeError(f'Existing incomplete pack preserved: {destination}')
        if (source / 'README.md').is_file():
            shutil.copyfile(source / 'README.md', destination / 'MODEL_CARD.md')
        print(f'{pair}: existing pack preserved', flush=True)
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    converter = ctranslate2.converters.TransformersConverter(str(source), copy_files=['source.spm', 'target.spm'])
    converter.convert(str(destination), quantization='int8')
    if (source / 'README.md').is_file():
        shutil.copyfile(source / 'README.md', destination / 'MODEL_CARD.md')
    manifest = {'source_repository': repo, 'revision': revision, 'source_lang': pair.split('-')[0],
        'target_lang': pair.split('-')[1], 'source_prefix': {'en-vi': '>>vie<<', 'en-zh': '>>cmn_Hans<<'}.get(pair, ''),
        'license': 'Apache-2.0', 'quantization': 'int8', 'files': {}}
    for path in destination.iterdir():
        if path.is_file():
            manifest['files'][path.name] = {'bytes': path.stat().st_size,
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    (destination / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    shutil.copyfile(source / 'source.spm', destination / 'source.spm')
    shutil.copyfile(source / 'target.spm', destination / 'target.spm')
    print(f'{pair}: {sum(p.stat().st_size for p in destination.iterdir() if p.is_file()) / 1024 / 1024:.1f} MiB', flush=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('pairs', nargs='+', choices=MODELS)
    parser.add_argument('--download-only', action='store_true')
    args = parser.parse_args()
    root = pathlib.Path(__file__).resolve().parent.parent
    for pair in args.pairs:
        prepare(pair, root, args.download_only)
