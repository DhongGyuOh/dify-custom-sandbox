FROM langgenius/dify-sandbox:0.2.12
USER root

# -----------------------------
# system build tools
# -----------------------------
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    python3-dev \
    wget \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Mecab install
# -----------------------------
RUN apt-get update && apt-get install -y \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8

# -----------------------------
# sandbox runtime directories
# -----------------------------
RUN mkdir -p /logs \
    && mkdir -p /var/sandbox \
    && mkdir -p /tmp \
    && chmod -R 777 /logs \
    && chmod -R 777 /var/sandbox \
    && chmod -R 777 /tmp

# -----------------------------
# python upgrade
# -----------------------------
RUN pip install --upgrade pip

# -----------------------------
# python libraries (버전 고정으로 RequestsDependencyWarning 제거 및 호환성 확보)
# requests 최신 버전을 먼저 설치하여 기본 종속성을 가져오고,
# 이후에 특정 버전을 명시하여 필요시 오버라이드합니다.
# -----------------------------
RUN pip install --no-cache-dir \
    requests==2.32.5 \
    urllib3==2.0.7 \
    chardet==5.2.0 \
    charset-normalizer==3.3.2 \
    pandas \
    numpy \
    scikit-learn \
    umap-learn \
    hdbscan \
    bertopic==0.17.4 \
    sentence-transformers==5.2.0 \
    plotly==5.19.0 \
    konlpy \
    mecab-python3 \
    crawl4ai \
    nest_asyncio \
    markdown2 \
    google-generativeai \
    aiohttp \
    flashtext \
    kobert-transformers

# -----------------------------
# playwright browser install
# -----------------------------
RUN playwright install --with-deps chromium

# -----------------------------
# sentence-transformer model pre-download
# (첫 실행 속도 개선 + 캐시 디렉토리 지정)
# -----------------------------
ENV HF_HOME=/var/sandbox/huggingface_cache
RUN mkdir -p ${HF_HOME} && chmod -R 777 ${HF_HOME}
RUN python - <<EOF
from sentence_transformers import SentenceTransformer
import os
os.environ["HF_HUB_OFFLINE"] = "0"  # 처음 다운로드 허용
# 'paraphrase-multilingual-MiniLM-L12-v2' 모델 로딩
try:
    model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
    print("Model downloaded and cached successfully")
except Exception as e:
    print(f"Failed to download model: {e}")
    # 필요한 경우, 여기서 오류 처리를 추가하거나 Dockerfile 빌드를 중단할 수 있습니다.
EOF

# -----------------------------
# permission fix (강화)
# /home/sandbox 디렉토리도 추가하여 sandbox 사용자의 홈 디렉토리 권한 문제 해결
# -----------------------------
RUN chmod -R 777 /usr/local/lib/python3.10 \
    && chmod -R 777 /root/.cache \
    && chmod -R 777 /var/sandbox \
    && mkdir -p /home/sandbox \
    && chmod -R 777 /home/sandbox \
    && chown -R sandbox:sandbox /home/sandbox

USER sandbox