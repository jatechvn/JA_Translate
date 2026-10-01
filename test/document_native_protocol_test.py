import ast, contextlib, io, json, pathlib, sys, threading, unittest
# Extract only protocol functions: importing the helper bootstraps document deps.
source=pathlib.Path('lib/modules/document_processor.py').read_text(encoding='utf-8')
tree=ast.parse(source)
functions=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in {'translate_text','get_cached_translation','set_cached_translation'}]
class ProtocolTests(unittest.TestCase):
 def setUp(self):
  self.scope={'json':json,'sys':sys,'_app_translation':True,'_engine_cache_prefix':'opus:','_app_lock':threading.Lock(),'_app_request_id':0,'_cache':{}}
  exec(compile(ast.Module(body=functions,type_ignores=[]),'<protocol>','exec'),self.scope)
 def test_native_response_and_unicode_request(self):
  original=sys.stdin
  try:
   sys.stdin=io.StringIO(json.dumps({'id':1,'text':'Vui lòng kiểm tra mạng.'})+'\n')
   output=io.StringIO()
   with contextlib.redirect_stdout(output):
    result=self.scope['translate_text']('Check the network.','en','vi','','','')
   self.assertEqual(result,'Vui lòng kiểm tra mạng.')
   self.assertEqual(json.loads(output.getvalue())['status'],'engine_request')
   self.assertIn('opus:en->vi:Check the network.',self.scope['_cache'])
  finally: sys.stdin=original
 def test_closed_channel_is_error(self):
  original=sys.stdin
  try:
   sys.stdin=io.StringIO('')
   with contextlib.redirect_stdout(io.StringIO()),self.assertRaisesRegex(RuntimeError,'channel closed'):
    self.scope['translate_text']('Hello','en','vi','','','')
  finally: sys.stdin=original
 def test_legacy_cache_does_not_shadow_native(self):
  self.scope['_cache']['en->vi:Hello']='old GGUF output'
  self.assertIsNone(self.scope['get_cached_translation']('Hello','en','vi'))
if __name__=='__main__': unittest.main()
