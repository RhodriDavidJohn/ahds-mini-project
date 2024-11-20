import os
from bertopic import BERTopic
from umap import UMAP
import plotly
from typing import List

# set a random seed to make the results reproducible
umap_model = UMAP(n_neighbors=15, n_components=5, 
                  min_dist=0.0, metric='cosine', random_state=36)

def train_model(text: List[str]) -> BERTopic:
    
    # define model
    topic_model = BERTopic(umap_model=umap_model)
    # train model
    topic_model.fit(text)
    
    topic_labels = topic_model.generate_topic_labels(nr_words=3, topic_prefix=False, separator=", ")
    topic_model.set_topic_labels(topic_labels)

    return topic_model

def plot_topic_trends(
        topic_model: BERTopic,
        text: List[str],
        dates: List[str],
        title: str,
        output_path: str
    ) -> plotly.graph_objects.Figure:

    # calculate topics over time
    topics_over_time = topic_model.topics_over_time(text, dates, nr_bins=20)

    # ploting topics over time
    fig = topic_model.visualize_topics_over_time(topics_over_time,
                                                 top_n_topics=5,
                                                 title=f'<b>Top 5 {title} Topics over Time</b>')
    fig.update_layout({'legend_entrywidth': 0,
                       'legend_entrywidthmode': 'pixels'})
    fig.update_xaxes(title_text="Date")
    # save the figure as a png file
    fig.write_image(os.path.join(output_path, f'{title}_topics_over_time.png'))

    return fig