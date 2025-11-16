#!/usr/bin/env python3
"""
Ollama Advanced Test Suite
Comprehensive testing and performance benchmarking
"""

import requests
import json
import time
import sys
import concurrent.futures
from datetime import datetime
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

class OllamaTestSuite:
    def __init__(self, base_url="http://localhost:11434"):
        self.base_url = base_url
        self.results = []
        
    def print_header(self, text):
        print(f"\n{Colors.BLUE}{'='*60}{Colors.NC}")
        print(f"{Colors.BLUE}{text:^60}{Colors.NC}")
        print(f"{Colors.BLUE}{'='*60}{Colors.NC}\n")
    
    def test_pass(self, name, details=""):
        print(f"{Colors.GREEN}✅ PASS{Colors.NC}: {name}")
        if details:
            print(f"   {details}")
        self.results.append(("PASS", name))
    
    def test_fail(self, name, details=""):
        print(f"{Colors.RED}❌ FAIL{Colors.NC}: {name}")
        if details:
            print(f"   {details}")
        self.results.append(("FAIL", name))
    
    def test_warn(self, name, details=""):
        print(f"{Colors.YELLOW}⚠️  WARN{Colors.NC}: {name}")
        if details:
            print(f"   {details}")
        self.results.append(("WARN", name))
    
    def test_connection(self):
        """Test Ollama API connection"""
        self.print_header("Test 1: API Connection")
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            if response.status_code == 200:
                self.test_pass("API Connection", f"Status: {response.status_code}")
                return True
            else:
                self.test_fail("API Connection", f"Status: {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            self.test_fail("Cannot connect to Ollama", str(e))
            return False
    
    def get_models(self) -> List[str]:
        """Get installed models"""
        self.print_header("Test 2: Model List")
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            data = response.json()
            models = [model['name'] for model in data.get('models', [])]
            
            if models:
                self.test_pass(f"Found {len(models)} model(s)")
                for model in models:
                    print(f"   • {model}")
                return models
            else:
                self.test_warn("No models installed")
                print("\nRecommended models:")
                print("   ollama pull mistral:7b-instruct")
                print("   ollama pull llama2:7b-chat")
                print("   ollama pull gemma:7b-instruct")
                return []
        except Exception as e:
            self.test_fail("Failed to get models", str(e))
            return []
    
    def test_inference(self, model: str) -> Tuple[bool, float]:
        """Test model inference"""
        self.print_header(f"Test 3: Inference - {model}")
        try:
            prompt = "Say 'Hello' in one word."
            
            print(f"Sending prompt: {prompt}")
            start_time = time.time()
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=60
            )
            
            elapsed = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                reply = data.get('response', '').strip()
                self.test_pass("Inference", f"Time: {elapsed:.2f}s")
                print(f"   Model reply: {reply}")
                
                # Performance rating
                if elapsed < 3:
                    print(f"   Performance: 🚀 Excellent")
                elif elapsed < 5:
                    print(f"   Performance: ✅ Good")
                elif elapsed < 10:
                    print(f"   Performance: ⚠️ Average")
                else:
                    print(f"   Performance: ❌ Slow")
                
                return True, elapsed
            else:
                self.test_fail("Inference", f"Status: {response.status_code}")
                return False, 0
        except Exception as e:
            self.test_fail("Inference error", str(e))
            return False, 0
    
    def test_openai_api(self, model: str) -> bool:
        """Test OpenAI-compatible API"""
        self.print_header(f"Test 4: OpenAI API - {model}")
        try:
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                json={
                    "model": model,
                    "messages": [
                        {"role": "user", "content": "Say hi"}
                    ],
                    "max_tokens": 10
                },
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                content = data['choices'][0]['message']['content']
                self.test_pass("OpenAI API", f"Reply: {content}")
                return True
            else:
                self.test_fail("OpenAI API", f"Status: {response.status_code}")
                return False
        except Exception as e:
            self.test_fail("OpenAI API error", str(e))
            return False
    
    def test_concurrent(self, model: str, num_requests: int = 4) -> Dict:
        """Test concurrent performance"""
        self.print_header(f"Test 5: Concurrent Performance - {model}")
        
        def single_request(i):
            try:
                start = time.time()
                response = requests.post(
                    f"{self.base_url}/api/generate",
                    json={
                        "model": model,
                        "prompt": f"Count to 3",
                        "stream": False
                    },
                    timeout=60
                )
                elapsed = time.time() - start
                return {"success": response.status_code == 200, "time": elapsed}
            except Exception as e:
                return {"success": False, "time": 0, "error": str(e)}
        
        print(f"Sending {num_requests} concurrent requests...")
        start_time = time.time()
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=num_requests) as executor:
            futures = [executor.submit(single_request, i) for i in range(num_requests)]
            results = [f.result() for f in concurrent.futures.as_completed(futures)]
        
        total_time = time.time() - start_time
        successful = sum(1 for r in results if r['success'])
        avg_time = sum(r['time'] for r in results if r['success']) / max(successful, 1)
        
        if successful == num_requests:
            self.test_pass("Concurrent test")
        elif successful > 0:
            self.test_warn(f"Partial success: {successful}/{num_requests}")
        else:
            self.test_fail("Concurrent test")
        
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Success rate: {successful}/{num_requests}")
        print(f"   Avg response: {avg_time:.2f}s")
        
        # Performance assessment
        if total_time < 15:
            print(f"   Concurrent rating: 🚀 Excellent (8-16 characters)")
            recommendation = 8
        elif total_time < 30:
            print(f"   Concurrent rating: ✅ Good (4-6 characters)")
            recommendation = 4
        else:
            print(f"   Concurrent rating: ⚠️ Average (2-4 characters)")
            recommendation = 2
        
        return {
            "total_time": total_time,
            "successful": successful,
            "avg_time": avg_time,
            "recommendation": recommendation
        }
    
    def test_microverse_compatibility(self, model: str) -> bool:
        """Test Microverse compatibility"""
        self.print_header(f"Test 6: Microverse Compatibility - {model}")
        
        # Simulate Microverse prompt
        test_prompt = """You are an office employee named Alice. Your position is: Project Manager.
Your personality is: Friendly, professional, responsible.

Current status:
- Money: 5000
- Mood: Happy
- Health: Good

Your current task is: Check today's work emails

Based on your position, personality and current status, should you continue this conversation?
1. Continue conversation
2. End conversation

Reply with only the number 1 or 2, no other text."""

        try:
            print("Simulating Microverse AI decision...")
            start_time = time.time()
            
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                json={
                    "model": model,
                    "messages": [
                        {"role": "user", "content": test_prompt}
                    ],
                    "max_tokens": 10,
                    "temperature": 0.7
                },
                timeout=60
            )
            
            elapsed = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                reply = data['choices'][0]['message']['content'].strip()
                
                print(f"   Model reply: {reply}")
                print(f"   Response time: {elapsed:.2f}s")
                
                # Check if reply follows instructions
                if '1' in reply or '2' in reply:
                    self.test_pass("Microverse compatibility")
                    print("   ✓ Understands structured prompts")
                    print("   ✓ Returns numbers as requested")
                else:
                    self.test_warn("Model understanding needs adjustment")
                    print("   ⚠ Did not strictly follow instructions")
                
                return True
            else:
                self.test_fail("Compatibility test", f"Status: {response.status_code}")
                return False
        except Exception as e:
            self.test_fail("Compatibility test error", str(e))
            return False
    
    def benchmark_tokens_per_second(self, model: str) -> float:
        """Test generation speed (tokens/s)"""
        self.print_header(f"Test 7: Speed Benchmark - {model}")
        
        try:
            prompt = "Write a short story about a robot in exactly 100 words."
            
            print("Testing token generation speed...")
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=120
            )
            
            if response.status_code == 200:
                data = response.json()
                total_duration = data.get('total_duration', 0) / 1e9  # Convert to seconds
                eval_count = data.get('eval_count', 0)
                
                if eval_count > 0 and total_duration > 0:
                    tokens_per_sec = eval_count / total_duration
                    self.test_pass("Speed benchmark")
                    print(f"   Generated tokens: {eval_count}")
                    print(f"   Total time: {total_duration:.2f}s")
                    print(f"   Generation speed: {tokens_per_sec:.2f} tokens/s")
                    
                    if tokens_per_sec > 20:
                        print(f"   Speed rating: 🚀 Very fast")
                    elif tokens_per_sec > 10:
                        print(f"   Speed rating: ✅ Fast")
                    elif tokens_per_sec > 5:
                        print(f"   Speed rating: ⚠️ Average")
                    else:
                        print(f"   Speed rating: ❌ Slow")
                    
                    return tokens_per_sec
                else:
                    self.test_warn("Cannot calculate speed")
                    return 0
            else:
                self.test_fail("Speed test")
                return 0
        except Exception as e:
            self.test_fail("Speed test error", str(e))
            return 0
    
    def generate_report(self, models: List[str], results: Dict):
        """Generate test report"""
        self.print_header("Test Report")
        
        passed = sum(1 for r in self.results if r[0] == "PASS")
        failed = sum(1 for r in self.results if r[0] == "FAIL")
        warned = sum(1 for r in self.results if r[0] == "WARN")
        
        print(f"{Colors.GREEN}Passed: {passed}{Colors.NC}")
        print(f"{Colors.RED}Failed: {failed}{Colors.NC}")
        print(f"{Colors.YELLOW}Warnings: {warned}{Colors.NC}")
        print()
        
        if failed == 0:
            print("🎉 All tests passed!")
            print("\nRecommended configuration:")
            if results.get('concurrent'):
                print(f"  • Concurrent characters: {results['concurrent'].get('recommendation', 4)}")
            if results.get('best_model'):
                print(f"  • Recommended model: {results['best_model']}")
            print(f"  • API URL: {self.base_url}/v1/chat/completions")
        else:
            print(f"❌ {failed} test(s) failed, please check configuration")
        
        # Save detailed report
        report_file = f"ollama_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "summary": {
                    "passed": passed,
                    "failed": failed,
                    "warned": warned
                },
                "models": models,
                "results": results
            }, f, indent=2, ensure_ascii=False)
        
        print(f"\nDetailed report saved to: {report_file}")

def main():
    print(f"""
{Colors.BLUE}╔═══════════════════════════════════════════════════════╗
║     Ollama Advanced Test Suite v1.0                   ║
║     For Microverse Project                            ║
╚═══════════════════════════════════════════════════════╝{Colors.NC}
""")
    
    tester = OllamaTestSuite()
    results = {}
    
    # Test 1: Connection
    if not tester.test_connection():
        print("\n❌ Cannot connect to Ollama, please ensure service is running:")
        print("   ollama serve")
        sys.exit(1)
    
    # Test 2: Get models
    models = tester.get_models()
    if not models:
        print("\nPlease install at least one model")
        sys.exit(1)
    
    # Select test model
    test_model = models[0]
    print(f"\nUsing model '{test_model}' for detailed testing\n")
    time.sleep(1)
    
    # Test 3: Inference
    success, inference_time = tester.test_inference(test_model)
    results['inference_time'] = inference_time
    
    if success:
        # Test 4: OpenAI API
        tester.test_openai_api(test_model)
        
        # Test 5: Concurrent
        concurrent_results = tester.test_concurrent(test_model, 4)
        results['concurrent'] = concurrent_results
        
        # Test 6: Microverse compatibility
        tester.test_microverse_compatibility(test_model)
        
        # Test 7: Generation speed
        tokens_per_sec = tester.benchmark_tokens_per_second(test_model)
        results['tokens_per_sec'] = tokens_per_sec
        
        results['best_model'] = test_model
    
    # Generate report
    tester.generate_report(models, results)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Colors.RED}Error occurred: {e}{Colors.NC}")
        sys.exit(1)

