import Foundation
import MLX
import MLXEmbedders
import VecturaKit

/// An embedder implementation using MLX library for generating vector embeddings.
public actor MLXEmbedder: VecturaEmbedder {
  private let modelContainer: ModelContainer
  private let configuration: ModelConfiguration
  private var cachedDimension: Int?

  /// Initializes an MLXEmbedder with the specified model configuration.
  ///
  /// - Parameter configuration: The MLX model configuration to use. Defaults to `.nomic_text_v1_5`.
  /// - Throws: An error if the model container cannot be loaded.
  public init(configuration: ModelConfiguration = .nomic_text_v1_5) async throws {
    self.configuration = configuration
    self.modelContainer = try await MLXEmbedders.loadModelContainer(configuration: configuration)
  }

  /// The dimensionality of the embedding vectors produced by this embedder.
  ///
  /// This value is cached after first detection to avoid repeated computation.
  /// - Throws: An error if the dimension cannot be determined.
  public var dimension: Int {
    get async throws {
      if let cached = cachedDimension {
        return cached
      }

      // Detect dimension by encoding a test string
      let testEmbedding = try await embed(text: "test")
      let dim = testEmbedding.count
      cachedDimension = dim
      return dim
    }
  }

  /// Generates embeddings for multiple texts in batch.
  ///
  /// - Parameter texts: The text strings to embed.
  /// - Returns: An array of embedding vectors, one for each input text.
  /// - Throws: An error if embedding generation fails.
  public func embed(texts: [String]) async throws -> [[Float]] {
    await modelContainer.perform { (model: EmbeddingModel, tokenizer, pooling) -> [[Float]] in
      let inputs = texts.map {
        tokenizer.encode(text: $0, addSpecialTokens: true)
      }

      // Pad to longest
      let maxLength = inputs.reduce(into: 16) { acc, elem in
        acc = max(acc, elem.count)
      }

      let padded = stacked(
        inputs.map { elem in
          MLXArray(
            elem
              + Array(
                repeating: tokenizer.eosTokenId ?? 0,
                count: maxLength - elem.count))
        })

      let mask = (padded .!= tokenizer.eosTokenId ?? 0)
      let tokenTypes = MLXArray.zeros(like: padded)

      let result = pooling(
        model(padded, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask),
        normalize: true, applyLayerNorm: true
      )

      return result.map { $0.asArray(Float.self) }
    }
  }
}
